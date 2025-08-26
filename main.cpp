#include <QDebug>
#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStandardPaths>
#include <kotki/kotki.h>
#include <mecab.h>
#include <memory>
#include <unicode/translit.h>
#include <unicode/unistr.h>

class TranslationBridge : public QObject
{
    Q_OBJECT
public:
    explicit TranslationBridge(QObject *parent = nullptr) : QObject(parent) {
        kotki = std::make_unique<Kotki>();

        QString registryFile = QStandardPaths::locate(
                                   QStandardPaths::GenericDataLocation, 
                                   QStringLiteral("localtranslate/models/firefox/registry.json")
                                   );

        if (!QFileInfo::exists(registryFile)) {
            throw std::runtime_error(QString("Registry file does not exist: %1").arg(registryFile).toStdString());
        }

        kotki->scan(std::filesystem::path(registryFile.toStdString()));
    }

    Q_INVOKABLE QString translate(const QString &text, const QString &langPair) const
    {
        std::string result = kotki->translate(text.toStdString(), langPair.toStdString());
        if(result.empty())
            return "Language pair \"" + langPair + "\" not available.";
        return QString::fromStdString(result);
    }

    Q_INVOKABLE QString transliterate(const QString &text, const QString &langCode) const
    {
        std::string input;

        // if input text is in japanese, first convert to katakana and then transliterate
        if (langCode == "ja") {
            input = kanjiToKatakana(text.toStdString());
        } else {
            input = text.toStdString();
        }

        UErrorCode status = U_ZERO_ERROR;
        std::unique_ptr<icu::Transliterator> trans(icu::Transliterator::createInstance("Any-Latin; Latin-ASCII", UTRANS_FORWARD, status));
        if (U_FAILURE(status) || !trans) {
            qWarning() << "Failed to create transliterator:" << u_errorName(status);
            return "";
        }
        icu::UnicodeString uText = icu::UnicodeString::fromUTF8(input);
        trans->transliterate(uText);
        std::string output;
        uText.toUTF8String(output);
        return QString::fromStdString(output);
    }

private:
    std::unique_ptr<Kotki> kotki = nullptr;

    std::string kanjiToKatakana(const std::string &text) const
    {
        std::unique_ptr<MeCab::Tagger> tagger(MeCab::createTagger(""));

        if (!tagger) {
            throw std::runtime_error("Failed to create MeCab tagger!");
        }

        std::istringstream input_stream(text);
        std::string line;
        std::ostringstream katakana_stream;
        bool first_line = true;

        while (std::getline(input_stream, line)) {
            if (!first_line) {
                katakana_stream << "\n";
            }
            first_line = false;

            const MeCab::Node *node = tagger->parseToNode(line.c_str());

            for (; node; node = node->next) {
                if (node->feature) {
                    std::string feature(node->feature);
                    std::vector<std::string> parts;
                    std::istringstream ss(feature);
                    std::string token;

                    while (std::getline(ss, token, ',')) {
                        parts.push_back(token);
                    }

                    if (parts.size() > 8 && parts[8] != "*") {
                        katakana_stream << parts[8] << " ";
                    }
                }
            }
        }

        return katakana_stream.str();
    }
};

#include "main.moc"


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setDesktopFileName(
        "dev.ters.LocalTranslate"); // specify name of the desktop file

    // Specify org details
    QCoreApplication::setOrganizationName("ters");
    QCoreApplication::setOrganizationDomain("ters.dev");
    QCoreApplication::setApplicationName("LocalTranslate");

    TranslationBridge bridge;

    QQmlApplicationEngine engine;

    // Expose the bridge to QML
    engine.rootContext()->setContextProperty("translationBridge", &bridge);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("LocalTranslate", "Main");

    return app.exec();
}

#include <initializer_list>

#include <QDebug>
#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStandardPaths>
#include <QCommandLineParser>
#include <QTextStream>

#include <kotki/kotki.h>
#include <mecab.h>
#include <memory>
#include <unicode/translit.h>
#include <unicode/unistr.h>

class TranslationBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList languages READ languages CONSTANT)
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

    QVariantList languages() const {
        QVariantList langList;
        const std::initializer_list<std::pair<const char*, const char*>> languageData = {
            {"ar", "Arabic"},
            {"az", "Azerbaijani"},
            {"be", "Belarusian"},
            {"bg", "Bulgarian"},
            {"bn", "Bengali"},
            {"bs", "Bosnian"},
            {"ca", "Catalan"},
            {"cs", "Czech"},
            {"da", "Danish"},
            {"de", "German"},
            {"el", "Greek"},
            {"en", "English"},
            {"es", "Spanish"},
            {"et", "Estonian"},
            {"fa", "Persian"},
            {"fi", "Finnish"},
            {"fr", "French"},
            {"gu", "Gujarati"},
            {"he", "Hebrew"},
            {"hi", "Hindi"},
            {"hr", "Croatian"},
            {"hu", "Hungarian"},
            {"id", "Indonesian"},
            {"is", "Icelandic"},
            {"it", "Italian"},
            {"ja", "Japanese"},
            {"kn", "Kannada"},
            {"ko", "Korean"},
            {"lt", "Lithuanian"},
            {"lv", "Latvian"},
            {"ml", "Malayalam"},
            {"ms", "Malay"},
            {"mt", "Maltese"},
            {"nb", "Norwegian Bokmål"},
            {"nl", "Dutch"},
            {"nn", "Norwegian Nynorsk"},
            {"pl", "Polish"},
            {"pt", "Portuguese"},
            {"ro", "Romanian"},
            {"ru", "Russian"},
            {"sk", "Slovak"},
            {"sl", "Slovenian"},
            {"sq", "Albanian"},
            {"sr", "Serbian"},
            {"sv", "Swedish"},
            {"ta", "Tamil"},
            {"te", "Telugu"},
            {"tr", "Turkish"},
            {"uk", "Ukrainian"},
            {"vi", "Vietnamese"},
            {"zh", "Chinese"}
        };

        for (const auto &lang : languageData) {
            langList.append(QVariantMap{{"code", lang.first}, {"name", lang.second}});
        }

        return langList;
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

int main(int argc, char *argv[]) {
    // Specify org details
    QCoreApplication::setOrganizationName("ters");
    QCoreApplication::setOrganizationDomain("ters.dev");
    QCoreApplication::setApplicationName("LocalTranslate");

    TranslationBridge bridge;

    if (argc > 1) { // CLI mode
        QCoreApplication app(argc, argv);
        QCommandLineParser parser;
        parser.setApplicationDescription("LocalTranslate CLI-mode");
        parser.addHelpOption();

        QCommandLineOption fromOption(
            "from", "Source language code.", "from");
        parser.addOption(fromOption);

        QCommandLineOption toOption("to", "Target language code.", "to");
        parser.addOption(toOption);

        QCommandLineOption listLanguagesOption("list-languages",
                                               "List available languages.");
        parser.addOption(listLanguagesOption);

        parser.process(app);
        QTextStream out(stdout);

        if (parser.isSet(listLanguagesOption)) {
            QVariantList languages = bridge.languages();
            for (const QVariant &lang : languages) {
                QVariantMap langMap = lang.toMap();
                out << langMap["code"].toString() << "\t" << langMap["name"].toString()
                    << Qt::endl;
            }
            return 0;
        }

        const QString from = parser.value(fromOption);
        const QString to = parser.value(toOption);
        const QStringList args = parser.positionalArguments();

        if (!from.isEmpty() && !to.isEmpty()) {
            QString textToTranslate;
            if (args.isEmpty()) {
                QTextStream in(stdin);
                textToTranslate = in.readAll();
            } else {
                textToTranslate = args.join(' ');
            }
            QString translatedText =
                bridge.translate(textToTranslate, from + to);
            out << translatedText << Qt::endl;
            return 0;
        } else {
            parser.showHelp(1);
        }
    } else { // GUI mode
        QGuiApplication app(argc, argv);
        QGuiApplication::setDesktopFileName(
            "dev.ters.LocalTranslate"); // specify name of the desktop file

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
}

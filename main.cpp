#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QStandardPaths>
#include <QDir>
#include <kotki/kotki.h>
#include <memory>
#include <unicode/translit.h>
#include <unicode/unistr.h>
#include <memory>

class TranslationBridge : public QObject
{
    Q_OBJECT
public:
    explicit TranslationBridge(QObject *parent = nullptr) : QObject(parent) {
        kotki = std::make_unique<Kotki>();

        QString appDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir dir(appDataDir);
        QString registryFile = dir.filePath("models/firefox/registry.json");

        if (!QFileInfo::exists(registryFile)) {
            throw std::runtime_error(QString("Registry file does not exist: %1").arg(registryFile).toStdString());
        }

        kotki->scan(std::filesystem::path(registryFile.toStdString()));
    }

    Q_INVOKABLE QString translate(const QString &text, const QString &langPair)
    {
        std::string result = kotki->translate(text.toStdString(), langPair.toStdString());
        if(result.empty())
            return "Language pair \"" + langPair + "\" not available.";
        return QString::fromStdString(result);
    }

    Q_INVOKABLE QString transliterate(const QString &text, const QString &langCode)
    {
        UErrorCode status = U_ZERO_ERROR;
        std::unique_ptr<icu::Transliterator> trans(icu::Transliterator::createInstance("Any-Latin; Latin-ASCII", UTRANS_FORWARD, status));
        if (U_FAILURE(status) || !trans) {
            qWarning() << "Failed to create transliterator:" << u_errorName(status);
            return "";
        }
        std::string input = text.toStdString();
        icu::UnicodeString uText = icu::UnicodeString::fromUTF8(input);
        trans->transliterate(uText);
        std::string output;
        uText.toUTF8String(output);
        return QString::fromStdString(output);
    }

private:
    std::unique_ptr<Kotki> kotki = nullptr;
};

#include "main.moc"


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    TranslationBridge bridge;

    QQmlApplicationEngine engine;

    // Expose the bridge to QML
    engine.rootContext()->setContextProperty("translationBridge", &bridge);

    const QUrl url(u"qrc:/LocalTranslate/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);
    return app.exec();
}

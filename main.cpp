#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QStandardPaths>
#include <QDir>
#include <kotki/kotki.h>
#include <memory>

// QObject wrapper for kotki
class TranslationBridge : public QObject
{
    Q_OBJECT
public:
    explicit TranslationBridge(QObject *parent = nullptr) : QObject(parent) {
        kotki = std::make_unique<Kotki>();

        QString appDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir dir(appDataDir);
        QString registryFile = dir.filePath("models/registry.json");

        if (!QFileInfo::exists(registryFile)) {
            throw std::runtime_error(QString("Registry file does not exist: %1").arg(registryFile).toStdString());
        }

        kotki->scan(std::filesystem::path(registryFile.toStdString()));
    }

    Q_INVOKABLE QString translate(const QString &text, const QString &langPair)
    {
        std::string result = kotki->translate(text.toStdString(), langPair.toStdString());
        if(result.empty())return "Language pair \"" + langPair + "\" not available.";
        return QString::fromStdString(result);
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

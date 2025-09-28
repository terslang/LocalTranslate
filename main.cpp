// SPDX-License-Identifier: GPL-3.0-only
#include <QDebug>
#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStandardPaths>
#include <QCommandLineParser>
#include <QTextStream>

#include "config.hpp"
#include "translation_bridge.hpp"

#include "main.moc"

int main(int argc, char *argv[]) {
    // Specify org details
    QCoreApplication::setOrganizationName("ters");
    QCoreApplication::setOrganizationDomain("ters.dev");
    QCoreApplication::setApplicationName("LocalTranslate");
    QCoreApplication::setApplicationVersion(LOCALTRANSLATE_VERSION);

    TranslationBridge bridge;

    if (argc > 1) { // CLI mode
        QCoreApplication app(argc, argv);
        QCommandLineParser parser;
        parser.setApplicationDescription("LocalTranslate CLI-mode");
        parser.addHelpOption();
        parser.addVersionOption();

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

// SPDX-License-Identifier: GPL-3.0-only
#include "translation_bridge.hpp"

#include <QStandardPaths>
#include <QFileInfo>

#include <mecab.h>
#include <unicode/translit.h>
#include <unicode/unistr.h>

TranslationBridge::TranslationBridge(QObject *parent) : QObject(parent) {
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

QVariantList TranslationBridge::languages() const {
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

QString TranslationBridge::translate(const QString &text, const QString &langPair) const {
    std::string result = kotki->translate(text.toStdString(), langPair.toStdString());
    if(result.empty())
        return "Language pair \"" + langPair + "\" not available.";
    return QString::fromStdString(result);
}

QString TranslationBridge::transliterate(const QString &text, const QString &langCode) const {
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

std::string TranslationBridge::kanjiToKatakana(const std::string &text) const {
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

// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <QObject>
#include <QVariantList>
#include <QString>
#include <memory>

#include <kotki/kotki.h>

class TranslationBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList languages READ languages CONSTANT)

public:
    explicit TranslationBridge(QObject *parent = nullptr);

    QVariantList languages() const;

    Q_INVOKABLE QString translate(const QString &text, const QString &langPair) const;
    Q_INVOKABLE QString transliterate(const QString &text, const QString &langCode) const;

private:
    std::unique_ptr<Kotki> kotki;

    std::string kanjiToKatakana(const std::string &text) const;
};
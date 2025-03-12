import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 768 / 2
    height: 768
    visible: true
    title: qsTr("LocalTranslate")

    Material.roundedScale: Material.SmallScale

    // The original array of objects with code + name
    readonly property var languages: [{
            "code": "bg",
            "name": "Bulgarian"
        }, {
            "code": "bs",
            "name": "Bosnian"
        }, {
            "code": "ca",
            "name": "Catalan"
        }, {
            "code": "cs",
            "name": "Czech"
        }, {
            "code": "da",
            "name": "Danish"
        }, {
            "code": "de",
            "name": "German"
        }, {
            "code": "el",
            "name": "Greek"
        }, {
            "code": "en",
            "name": "English"
        }, {
            "code": "es",
            "name": "Spanish"
        }, {
            "code": "et",
            "name": "Estonian"
        }, {
            "code": "fa",
            "name": "Persian"
        }, {
            "code": "fi",
            "name": "Finnish"
        }, {
            "code": "fr",
            "name": "French"
        }, {
            "code": "hr",
            "name": "Croatian"
        }, {
            "code": "hu",
            "name": "Hungarian"
        }, {
            "code": "id",
            "name": "Indonesian"
        }, {
            "code": "is",
            "name": "Icelandic"
        }, {
            "code": "it",
            "name": "Italian"
        }, {
            "code": "ja",
            "name": "Japanese"
        }, {
            "code": "ko",
            "name": "Korean"
        }, {
            "code": "lt",
            "name": "Lithuanian"
        }, {
            "code": "lv",
            "name": "Latvian"
        }, {
            "code": "mt",
            "name": "Maltese"
        }, {
            "code": "nb",
            "name": "Norwegian Bokmål"
        }, {
            "code": "nl",
            "name": "Dutch"
        }, {
            "code": "nn",
            "name": "Norwegian Nynorsk"
        }, {
            "code": "pl",
            "name": "Polish"
        }, {
            "code": "pt",
            "name": "Portuguese"
        }, {
            "code": "ro",
            "name": "Romanian"
        }, {
            "code": "ru",
            "name": "Russian"
        }, {
            "code": "sk",
            "name": "Slovak"
        }, {
            "code": "sl",
            "name": "Slovenian"
        }, {
            "code": "sr",
            "name": "Serbian"
        }, {
            "code": "sv",
            "name": "Swedish"
        }, {
            "code": "tr",
            "name": "Turkish"
        }, {
            "code": "uk",
            "name": "Ukrainian"
        }, {
            "code": "vi",
            "name": "Vietnamese"
        }, {
            "code": "zh",
            "name": "Chinese"
        }]

    readonly property var sortedLanguages: languages.sort(
                                               (a, b) => a.name
                                               > b.name ? 1 : (b.name > a.name ? -1 : 0))

    // Languages that don't use Latin script
    readonly property var nonLatinLangs: ["bg", "el", "fa", "ja", "ko", "ru", "uk", "zh", "sr", "mt"]

    readonly property int controlRowHeight: 50
    readonly property bool isLandscape: width > height

    RowLayout {
        id: topRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        spacing: 0
        Text {
            text: "Local"
            color: Material.primaryTextColor
            font.pixelSize: 24
        }
        Text {
            text: "Translate"
            color: Material.primaryTextColor
            font.pixelSize: 24
            font.bold: true
        }
        Item {
            Layout.fillWidth: true
        }

        Button {
            id: themeButton
            // No text
            text: ""
            icon.source: (window.Material.theme
                          === Material.Light) ? "qrc:/images/moon.png" : "qrc:/images/sun.png"
            onClicked: {
                window.Material.theme = (window.Material.theme
                                         === Material.Light) ? Material.Dark : Material.Light
            }
        }
    }

    // ========== MAIN LAYOUT ==========
    // We use 3 columns in landscape (from-frame | swap-button | to-frame)
    // and 1 column in portrait (stack them top to bottom).
    // So effectively, in portrait it's:
    // Row 0: from-frame
    // Row 1: swap-button
    // Row 2: to-frame
    GridLayout {
        anchors.top: topRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        rowSpacing: 4
        columnSpacing: 4
        anchors.margins: 8

        columns: isLandscape ? 3 : 1
        rows: isLandscape ? 1 : 3

        // === SOURCE FRAME ===
        Frame {
            id: fromFrame
            Material.roundedScale: Material.SmallScale
            Layout.fillWidth: true
            Layout.fillHeight: true

            // If landscape => row=0, col=0
            // If portrait  => row=0, col=0
            Layout.row: isLandscape ? 0 : 0
            Layout.column: isLandscape ? 0 : 0

            contentItem: Item {
                anchors.fill: parent

                ComboBox {
                    Material.roundedScale: Material.SmallScale
                    id: fromLangCombo
                    width: 200
                    font.pixelSize: 12
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 8
                    anchors.leftMargin: 8

                    model: window.sortedLanguages
                    textRole: "name"
                    valueRole: "code"
                    currentIndex: window.sortedLanguages.findIndex(
                                      lang => lang.code === "en")

                    onCurrentIndexChanged: {
                        // Clear the existing result
                        resultText.text = ""
                    }
                }

                // ScrollView for source text
                ScrollView {
                    Material.roundedScale: Material.SmallScale
                    id: sourceScrollView
                    anchors.top: fromLangCombo.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 4
                    anchors.bottom: fromTransliterationText.visible ? fromTransliterationText.top : fromBottomRow.top

                    TextArea {
                        Material.roundedScale: Material.SmallScale
                        id: sourceText
                        placeholderText: qsTr("Enter text to translate...")
                        wrapMode: TextEdit.Wrap
                    }
                }

                // Display transliteration if non-Latin
                Text {
                    id: fromTransliterationText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: fromBottomRow.top
                    anchors.bottomMargin: visible ? 4 : 0
                    wrapMode: TextEdit.Wrap
                    leftPadding: 8
                    rightPadding: 8
                    topPadding: 4
                    horizontalAlignment: Text.AlignLeft
                    font.pointSize: 12
                    visible: text !== ""
                    color: Material.secondaryTextColor

                    text: {
                        let fromCode = fromLangCombo.currentValue
                        if (window.nonLatinLangs.includes(fromCode)) {
                            return translationBridge.transliterate(
                                        sourceText.text, fromCode)
                        }
                        return ""
                    }
                }

                RowLayout {
                    id: fromBottomRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 8
                    anchors.leftMargin: 8
                    anchors.bottomMargin: 2
                    height: window.controlRowHeight

                    Button {
                        Material.roundedScale: Material.SmallScale
                        id: pasteButton
                        icon.source: "qrc:/images/paste.png"
                        width: 28
                        height: 28
                        font.pixelSize: 12
                        onClicked: sourceText.paste()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        Material.roundedScale: Material.SmallScale
                        id: translateButton
                        text: qsTr("Translate")
                        width: 80
                        height: 28
                        highlighted: true
                        font.pixelSize: 12
                        font.bold: true
                        onClicked: {
                            if (sourceText.text.trim() === "")
                                return
                            let fromLangCode = fromLangCombo.currentValue
                            let toLangCode = toLangCombo.currentValue
                            let langPair = fromLangCode + toLangCode

                            let result = translationBridge.translate(
                                    sourceText.text, langPair)
                            resultText.text = result
                        }
                    }
                }
            }
        }

        // === SWAP BUTTON IN THE MIDDLE ===
        Button {
            id: swapButton
            Material.roundedScale: Material.SmallScale
            icon.source: isLandscape ? "qrc:/images/arrow-left-right.png" : "qrc:/images/arrow-down-up.png"
            // If landscape => row=0, col=1
            // If portrait  => row=1, col=0
            Layout.row: isLandscape ? 0 : 1
            Layout.column: isLandscape ? 1 : 0
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            onClicked: {
                // If result text is not empty, move it to the source and clear it
                if (resultText.text.trim() !== "") {
                    sourceText.text = resultText.text
                    resultText.text = ""
                }

                // Swap languages
                var oldIndex = fromLangCombo.currentIndex
                fromLangCombo.currentIndex = toLangCombo.currentIndex
                toLangCombo.currentIndex = oldIndex
            }
        }

        // === RESULT FRAME ===
        Frame {
            id: toFrame
            Material.roundedScale: Material.SmallScale
            Layout.fillWidth: true
            Layout.fillHeight: true

            // If landscape => row=0, col=2
            // If portrait  => row=2, col=0
            Layout.row: isLandscape ? 0 : 2
            Layout.column: isLandscape ? 2 : 0

            contentItem: Item {
                anchors.fill: parent

                ComboBox {
                    Material.roundedScale: Material.SmallScale
                    id: toLangCombo
                    width: 200
                    font.pixelSize: 12
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 8
                    anchors.leftMargin: 8

                    model: window.sortedLanguages
                    textRole: "name"
                    valueRole: "code"
                    currentIndex: window.sortedLanguages.findIndex(
                                      lang => lang.code === "de")

                    onCurrentIndexChanged: {
                        resultText.text = ""
                    }
                }

                ScrollView {
                    Material.roundedScale: Material.SmallScale
                    id: resultScrollView
                    anchors.top: toLangCombo.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 4
                    anchors.bottom: toTransliterationText.visible ? toTransliterationText.top : toBottomRow.top

                    TextArea {
                        Material.roundedScale: Material.SmallScale
                        id: resultText
                        placeholderText: qsTr("Translation will appear here")
                        wrapMode: TextEdit.Wrap
                        readOnly: true
                        selectByMouse: true
                    }
                }

                Text {
                    id: toTransliterationText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: toBottomRow.top
                    anchors.bottomMargin: visible ? 4 : 0
                    wrapMode: TextEdit.Wrap
                    leftPadding: 8
                    rightPadding: 8
                    topPadding: 4
                    horizontalAlignment: Text.AlignLeft
                    font.pointSize: 12
                    visible: text !== ""
                    color: Material.hintTextColor

                    text: {
                        let toCode = toLangCombo.currentValue
                        if (window.nonLatinLangs.includes(toCode)) {
                            return translationBridge.transliterate(
                                        resultText.text, toCode)
                        }
                        return ""
                    }
                }

                RowLayout {
                    id: toBottomRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.bottomMargin: 2
                    height: window.controlRowHeight

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        Material.roundedScale: Material.SmallScale
                        id: copyButton
                        icon.source: "qrc:/images/copy.png"
                        font.pixelSize: 12
                        onClicked: {
                            if (resultText.text.length > 0) {
                                resultText.selectAll()
                                resultText.copy()
                                resultText.deselect()
                            }
                        }
                    }
                }
            }
        }
    }
}

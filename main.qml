import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.FluentWinUI3

ApplicationWindow {
    id: window
    width: 720 / 1.618
    height: 720
    visible: true
    title: qsTr("LocalTranslate")

    // The original array of objects with code + name
    readonly property var languages: [{
            "code": "ar",
            "name": "Arabic"
        }, {
            "code": "az",
            "name": "Azerbaijani"
        }, {
            "code": "be",
            "name": "Belarusian"
        }, {
            "code": "bg",
            "name": "Bulgarian"
        }, {
            "code": "bn",
            "name": "Bengali"
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
            "code": "gu",
            "name": "Gujarati"
        }, {
            "code": "he",
            "name": "Hebrew"
        }, {
            "code": "hi",
            "name": "Hindi"
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
            "code": "kn",
            "name": "Kannada"
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
            "code": "ml",
            "name": "Malayalam"
        }, {
            "code": "ms",
            "name": "Malay"
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
            "code": "sq",
            "name": "Albanian"
        }, {
            "code": "sr",
            "name": "Serbian"
        }, {
            "code": "sv",
            "name": "Swedish"
        }, {
            "code": "ta",
            "name": "Tamil"
        }, {
            "code": "te",
            "name": "Telugu"
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
    readonly property var nonLatinLangs: ["ar", "be", "bg", "bn", "el", "fa", "gu", "he", "hi", "ja", "kn", "ko", "ml", "mt", "ru", "sr", "ta", "te", "uk", "zh"]

    readonly property int controlRowHeight: 50
    readonly property bool isLandscape: width > height

    function doTranslate() {
        if (sourceText.text.trim() === "")
            return
        let fromLangCode = fromLangCombo.currentValue
        let toLangCode = toLangCombo.currentValue
        let langPair = fromLangCode + toLangCode

        let result = translationBridge.translate(
                sourceText.text, langPair)
        resultText.text = result
    }

    Shortcut {
        sequences: ["Ctrl+Enter", "Ctrl+Return"]
        context: Qt.ApplicationShortcut
        onActivated: window.doTranslate()
    }

    RowLayout {
        id: topRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        spacing: 0
        Text {
            id: slimLogoText
            text: "Local"
            color: window.palette.text
            font.pixelSize: 24
        }
        Text {
            id: boldLogoText
            text: "Translate"
            color: window.palette.text
            font.pixelSize: 24
            font.bold: true
        }
        Item {
            Layout.fillWidth: true
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

            Layout.fillWidth: true
            Layout.fillHeight: true

            // If landscape => row=0, col=0
            // If portrait  => row=0, col=0
            Layout.row: isLandscape ? 0 : 0
            Layout.column: isLandscape ? 0 : 0

            contentItem: Item {
                anchors.fill: parent

                ComboBox {
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
                    id: sourceScrollView
                    anchors.top: fromLangCombo.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 4
                    anchors.bottom: fromTransliterationText.visible ? fromTransliterationText.top : fromBottomRow.top

                    TextArea {
                        id: sourceText
                        placeholderText: qsTr("Enter text to translate...")
                        wrapMode: TextEdit.Wrap
                        verticalAlignment: TextEdit.AlignTop
                    }
                }

                // Display transliteration if non-Latin
                Text {
                    id: fromTransliterationText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: fromBottomRow.top
                    anchors.bottomMargin: visible ? 4 : 0
                    leftPadding: 8
                    rightPadding: 8
                    topPadding: 4
                    horizontalAlignment: Text.AlignLeft
                    font.pointSize: 12
                    color: window.palette.placeholderText
                    visible: text !== ""

                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    clip: true
                    maximumLineCount: parent.height / 2 / (font.pixelSize * 1.5)

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
                        id: translateButton
                        text: qsTr("Translate")
                        width: 80
                        height: 28
                        highlighted: true
                        font.pixelSize: 12
                        font.bold: true
                        onClicked: window.doTranslate()

                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Ctrl+Enter")
                        ToolTip.delay: 300
                    }
                }
            }
        }

        // === SWAP BUTTON IN THE MIDDLE ===
        Button {
            id: swapButton

            icon.source: isLandscape ? "qrc:/images/arrow-left-right.png" : "qrc:/images/arrow-down-up.png"
            // If landscape => row=0, col=1
            // If portrait  => row=1, col=0
            Layout.row: isLandscape ? 0 : 1
            Layout.column: isLandscape ? 1 : 0
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.preferredWidth: window.isLandscape ? 40 : implicitWidth
            Layout.preferredHeight: window.isLandscape ? 40 : implicitHeight

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

            Layout.fillWidth: true
            Layout.fillHeight: true

            // If landscape => row=0, col=2
            // If portrait  => row=2, col=0
            Layout.row: isLandscape ? 0 : 2
            Layout.column: isLandscape ? 2 : 0

            contentItem: Item {
                anchors.fill: parent

                ComboBox {

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
                    id: resultScrollView
                    anchors.top: toLangCombo.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 4
                    anchors.bottom: toTransliterationText.visible ? toTransliterationText.top : toBottomRow.top

                    TextArea {
                        id: resultText
                        placeholderText: qsTr("Translation will appear here")
                        wrapMode: TextEdit.Wrap
                        readOnly: true
                        selectByMouse: true
                        verticalAlignment: TextEdit.AlignTop
                    }
                }

                Text {
                    id: toTransliterationText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: toBottomRow.top
                    anchors.bottomMargin: visible ? 4 : 0
                    leftPadding: 8
                    rightPadding: 8
                    topPadding: 4
                    horizontalAlignment: Text.AlignLeft
                    font.pointSize: 12
                    color: window.palette.placeholderText
                    visible: text !== ""

                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    clip: true
                    maximumLineCount: parent.height / 2 / (font.pixelSize * 1.5)

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

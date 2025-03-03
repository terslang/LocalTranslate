import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 480
    height: 720
    visible: true
    title: qsTr("LocalTranslate")

    // The original array of objects with code + name
    property var languages: [{
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

    property var sortedLanguages: languages.sort(
                                      (a, b) => (a.name > b.name) ? 1 : ((b.name > a.name) ? -1 : 0)) // sort by name

    // Languages that don't use latin script, these langs need transliteration
    // Bulgarian, Greek, Persian, Japanese, Korean, Russian, Ukrainian, Chinese, Serbian, Maltese
    property var nonLatinLangs: ["bg", "el", "fa", "ja", "ko", "ru", "uk", "zh", "sr", "mt"]

    property int textAreaHeight: 250
    property int controlRowHeight: 50
    property int frameHeight: textAreaHeight + 2 * controlRowHeight
    property bool isLandscape: width > height
    property int effectiveFrameHeight: isLandscape ? frameHeight : ((height - (8 * 2 + 12)) / 2)

    onWidthChanged: isLandscape = (width > height)
    onHeightChanged: isLandscape = (width > height)

    SystemPalette {
        id: palette
        colorGroup: SystemPalette.Active
    }
    color: palette.window

    GridLayout {
        anchors.fill: parent
        rowSpacing: 12
        columnSpacing: 12
        anchors.margins: 8
        columns: window.isLandscape ? 2 : 1

        // === SOURCE FRAME ===
        Frame {
            Layout.fillWidth: true
            Layout.preferredHeight: window.effectiveFrameHeight
            background: Rectangle {
                color: palette.base
                radius: 4
            }

            contentItem: Item {
                anchors.fill: parent

                ComboBox {
                    id: fromLangCombo
                    width: 200
                    height: 32
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 8
                    anchors.leftMargin: 8
                    popup.height: 330

                    model: window.sortedLanguages
                    textRole: 'name'
                    valueRole: 'code'
                    currentIndex: window.sortedLanguages.findIndex(
                                      lang => lang.code === 'en')
                }

                ScrollView {
                    id: sourceScrollView
                    anchors.top: fromLangCombo.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 4
                    height: window.isLandscape ? window.textAreaHeight : (window.effectiveFrameHeight - 2 * window.controlRowHeight)

                    TextArea {
                        id: sourceText
                        width: sourceScrollView.width
                        height: sourceScrollView.height
                        placeholderText: qsTr("Enter text to translate...")
                        placeholderTextColor: palette.placeholderText
                        wrapMode: TextEdit.Wrap
                        color: palette.text
                        background: null
                        readOnly: false
                        clip: true
                    }
                }

                Text {
                    id: fromTransliterationText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: fromBottomRow.top
                    wrapMode: TextEdit.Wrap
                    leftPadding: 8
                    rightPadding: 8
                    topPadding: 4
                    horizontalAlignment: Text.AlignLeft
                    color: palette.placeholderText
                    font.pointSize: 12
                    text: {
                        let fromCode = fromLangCombo.currentValue
                        if (window.nonLatinLangs.includes(fromCode))
                            return translationBridge.transliterate(
                                        sourceText.text, fromCode)
                        return ""
                    }
                    visible: text !== ""
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
                        icon.name: "edit-paste"
                        icon.color: "transparent"
                        background: Rectangle {
                            anchors.fill: parent
                            color: palette.button
                            radius: 4
                        }
                        padding: 8
                        onClicked: sourceText.paste()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        id: translateButton
                        text: qsTr("Translate")
                        background: Rectangle {
                            anchors.fill: parent
                            color: palette.highlight
                            radius: 4
                        }
                        contentItem: Text {
                            text: translateButton.text
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: palette.highlightedText
                        }
                        padding: 8
                        onClicked: {
                            // Prevent empty source from calling translate
                            if (sourceText.text.trim() === "")
                                return

                            // 1) Get selected name from fromLangCombo.text
                            let fromLangCode = fromLangCombo.currentValue

                            // 2) Get selected name from toLangCombo.text
                            let toLangCode = toLangCombo.currentValue

                            // 3) Construct the language pair
                            let langPair = fromLangCode + toLangCode

                            // 4) Perform translation
                            let result = translationBridge.translate(
                                    sourceText.text, langPair)
                            resultText.text = result
                        }
                    }
                }
            }
        }

        // === RESULT FRAME ===
        Frame {
            Layout.fillWidth: true
            Layout.preferredHeight: window.effectiveFrameHeight
            background: Rectangle {
                color: palette.base
                radius: 4
            }

            contentItem: Item {
                anchors.fill: parent

                ComboBox {
                    id: toLangCombo
                    width: 200
                    height: 32
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 8
                    anchors.leftMargin: 8
                    popup.height: 330

                    model: window.sortedLanguages
                    textRole: 'name'
                    valueRole: 'code'
                    currentIndex: window.sortedLanguages.findIndex(
                                      lang => lang.code === 'de')
                }

                ScrollView {
                    id: resultScrollView
                    anchors.top: toLangCombo.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 4
                    height: window.isLandscape ? window.textAreaHeight : (window.effectiveFrameHeight - 2 * window.controlRowHeight)

                    TextArea {
                        id: resultText
                        width: resultScrollView.width
                        placeholderText: qsTr("Translation will appear here")
                        placeholderTextColor: palette.placeholderText
                        wrapMode: TextEdit.Wrap
                        color: palette.text
                        background: null
                        readOnly: true
                        selectByMouse: true
                        clip: true
                    }
                }

                Text {
                    id: toTransliterationText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: toBottomRow.top
                    wrapMode: TextEdit.Wrap
                    leftPadding: 8
                    rightPadding: 8
                    topPadding: 4
                    horizontalAlignment: Text.AlignLeft
                    color: palette.placeholderText
                    font.pointSize: 12
                    text: {
                        let toCode = toLangCombo.currentValue
                        if (window.nonLatinLangs.includes(toCode))
                            return translationBridge.transliterate(
                                        resultText.text, toCode)
                        return ""
                    }
                    visible: text !== ""
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
                        background: Rectangle {
                            anchors.fill: parent
                            color: palette.button
                            radius: 4
                        }
                        icon.name: "edit-copy"
                        icon.color: "transparent"
                        padding: 8
                        onClicked: resultText.copy()
                    }
                }
            }
        }
    }
}

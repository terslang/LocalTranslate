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

    // The existing properties for dimensions, etc.
    property int textAreaHeight: 250
    property int controlRowHeight: 50
    property int frameHeight: textAreaHeight + 2 * controlRowHeight
    property bool isLandscape: width > height

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
            Layout.fillHeight: true
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

                    model: window.sortedLanguages
                    textRole: "name"
                    valueRole: "code"
                    currentIndex: window.sortedLanguages.findIndex(
                                      lang => lang.code === "en")

                    background: Rectangle {
                        anchors.fill: parent
                        color: palette.alternateBase
                        radius: 4
                    }

                    contentItem: Text {
                        text: fromLangCombo.displayText
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        color: palette.text
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                    }

                    delegate: ItemDelegate {
                        width: fromLangCombo.width
                        height: 32
                        highlighted: fromLangCombo.highlightedIndex == index
                        background: Rectangle {
                            anchors.fill: parent
                            color: highlighted ? palette.midlight : palette.alternateBase
                            radius: 4
                        }
                        contentItem: Text {
                            text: modelData.name
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 8
                            color: palette.text
                            elide: Text.ElideRight
                        }
                        onClicked: {
                            fromLangCombo.currentIndex = index
                            fromLangCombo.popup.close()
                        }
                    }

                    popup: Popup {
                        width: fromLangCombo.width
                        implicitHeight: 330
                        padding: 0
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: fromLangCombo.popup.visible ? fromLangCombo.delegateModel : null
                            currentIndex: fromLangCombo.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                        background: Rectangle {
                            radius: 4
                            color: palette.alternateBase
                        }
                    }

                    onCurrentIndexChanged: {
                        // Clear the existing result whenever the user changes 'from' language
                        resultText.text = ""
                    }
                }

                // Anchor this ScrollView’s bottom to the transliteration text’s top
                // so it shrinks if the transliteration text grows.
                ScrollView {
                    id: sourceScrollView
                    anchors.top: fromLangCombo.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 4
                    // Instead of a fixed height, anchor to fromTransliterationText
                    anchors.bottom: fromTransliterationText.top

                    TextArea {
                        id: sourceText
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
                    anchors.bottomMargin: 4
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
                        icon.color: palette.text
                        icon.source: "qrc:/images/paste.png"
                        background: Rectangle {
                            anchors.fill: parent
                            color: pasteButton.down ? palette.highlight : palette.button
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
                            color: translateButton.down ? palette.highlight : palette.accent
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

        // === RESULT FRAME ===
        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
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

                    model: window.sortedLanguages
                    textRole: "name"
                    valueRole: "code"
                    currentIndex: window.sortedLanguages.findIndex(
                                      lang => lang.code === "de")

                    background: Rectangle {
                        anchors.fill: parent
                        color: palette.alternateBase
                        radius: 4
                    }

                    contentItem: Text {
                        text: toLangCombo.displayText
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        color: palette.text
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                    }

                    delegate: ItemDelegate {
                        width: toLangCombo.width
                        height: 32
                        highlighted: toLangCombo.highlightedIndex == index
                        background: Rectangle {
                            anchors.fill: parent
                            color: highlighted ? palette.midlight : palette.alternateBase
                            radius: 4
                        }
                        contentItem: Text {
                            text: modelData.name
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 8
                            color: palette.text
                            elide: Text.ElideRight
                        }
                        onClicked: {
                            toLangCombo.currentIndex = index
                            toLangCombo.popup.close()
                        }
                    }

                    popup: Popup {
                        width: toLangCombo.width
                        implicitHeight: 330
                        padding: 0
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: toLangCombo.popup.visible ? toLangCombo.delegateModel : null
                            currentIndex: toLangCombo.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                        background: Rectangle {
                            radius: 4
                            color: palette.alternateBase
                        }
                    }

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
                    anchors.bottom: toTransliterationText.top

                    TextArea {
                        id: resultText
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
                    anchors.bottomMargin: 4
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
                            color: copyButton.down ? palette.highlight : palette.button
                            radius: 4
                        }
                        icon.name: "edit-copy"
                        icon.color: palette.text
                        icon.source: "qrc:/images/copy.png"
                        padding: 8
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

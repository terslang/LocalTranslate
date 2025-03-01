import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

ApplicationWindow {
    id: window
    width: 480
    height: 720
    visible: true
    title: qsTr("LocalTranslate")

    // The original array of objects with code + name
    property var languages: [
        { code: "bg", name: "Bulgarian" },
        { code: "bs", name: "Bosnian" },
        { code: "ca", name: "Catalan" },
        { code: "cs", name: "Czech" },
        { code: "da", name: "Danish" },
        { code: "de", name: "German" },
        { code: "el", name: "Greek" },
        { code: "en", name: "English" },
        { code: "es", name: "Spanish" },
        { code: "et", name: "Estonian" },
        { code: "fa", name: "Persian" },
        { code: "fi", name: "Finnish" },
        { code: "fr", name: "French" },
        { code: "hr", name: "Croatian" },
        { code: "hu", name: "Hungarian" },
        { code: "id", name: "Indonesian" },
        { code: "is", name: "Icelandic" },
        { code: "it", name: "Italian" },
        { code: "ja", name: "Japanese" },
        { code: "ko", name: "Korean" },
        { code: "lt", name: "Lithuanian" },
        { code: "lv", name: "Latvian" },
        { code: "mt", name: "Maltese" },
        { code: "nb", name: "Norwegian Bokmål" },
        { code: "nl", name: "Dutch" },
        { code: "nn", name: "Norwegian Nynorsk" },
        { code: "pl", name: "Polish" },
        { code: "pt", name: "Portuguese" },
        { code: "ro", name: "Romanian" },
        { code: "ru", name: "Russian" },
        { code: "sk", name: "Slovak" },
        { code: "sl", name: "Slovenian" },
        { code: "sr", name: "Serbian" },
        { code: "sv", name: "Swedish" },
        { code: "tr", name: "Turkish" },
        { code: "uk", name: "Ukrainian" },
        { code: "vi", name: "Vietnamese" },
        { code: "zh", name: "Chinese" }
    ]

    // Build a plain string list of language names
    property var languageNames: languages.map(lang => lang.name)

    property int textAreaHeight: 250
    property int controlRowHeight: 50
    property int frameHeight: textAreaHeight + 2 * controlRowHeight
    property bool isLandscape: width > height
    property int effectiveFrameHeight: isLandscape
        ? frameHeight
        : ((height - (8 * 2 + 12)) / 2)

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
        columns: isLandscape ? 2 : 1

        // === SOURCE FRAME ===
        Frame {
            Layout.fillWidth: true
            Layout.preferredHeight: effectiveFrameHeight
            background: Rectangle {
                color: palette.base
                radius: 4
            }

            contentItem: Item {
                anchors.fill: parent

                SearchableComboBox {
                    id: fromLangCombo
                    width: 200
                    height: 32
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 8
                    anchors.leftMargin: 8

                    imodel: window.languageNames

                    // Default selection index => "English"
                    currentIndex: 7
                }

                ScrollView {
                    id: sourceScrollView
                    anchors.top: fromLangCombo.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 4
                    height: isLandscape
                        ? textAreaHeight
                        : (effectiveFrameHeight - 2 * controlRowHeight)

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

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 8
                    anchors.leftMargin: 8
                    anchors.bottomMargin: 2
                    height: controlRowHeight

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

                    Item { Layout.fillWidth: true }

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
                            if (sourceText.text.trim() === "") return

                            // 1) Get selected "name" from fromLangCombo
                            let fromName = languageNames[fromLangCombo.currentIndex]
                            // 2) Find the corresponding object
                            let fromObj = languages.find(lang => lang.name === fromName)
                            let fromLangCode = fromObj ? fromObj.code : "en"

                            // 3) Do the same for toLangCombo
                            let toName = languageNames[toLangCombo.currentIndex]
                            let toObj = languages.find(lang => lang.name === toName)
                            let toLangCode = toObj ? toObj.code : "de"

                            // 4) Construct the language pair
                            let langPair = fromLangCode + toLangCode
                            let result = translationBridge.translate(sourceText.text, langPair)
                            resultText.text = result
                        }
                    }
                }
            }
        }

        // === RESULT FRAME ===
        Frame {
            Layout.fillWidth: true
            Layout.preferredHeight: effectiveFrameHeight
            background: Rectangle {
                color: palette.base
                radius: 4
            }

            contentItem: Item {
                anchors.fill: parent

                SearchableComboBox {
                    id: toLangCombo
                    width: 200
                    height: 32
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 8
                    anchors.leftMargin: 8

                    // Pass the same string list.
                    imodel: window.languageNames

                    // Default to "German" => index 5
                    currentIndex: 5
                }

                ScrollView {
                    id: resultScrollView
                    anchors.top: toLangCombo.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 4
                    height: isLandscape
                        ? textAreaHeight
                        : (effectiveFrameHeight - 2 * controlRowHeight)

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

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.bottomMargin: 2
                    height: controlRowHeight

                    Item { Layout.fillWidth: true }

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

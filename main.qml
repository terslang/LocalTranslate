import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 480
    height: 720
    visible: true
    title: qsTr("LocalTranslate")

    // Define one common language model for both ComboBoxes.
    property var languages: [
        "bg", "bs", "ca", "cs", "da", "de", "el",
        "en", "es", "et", "fa", "fi", "fr", "hr",
        "hu", "id", "is", "it", "ja", "ko", "lt",
        "lv", "mt", "nb", "nl", "nn", "pl", "pt",
        "ro", "ru", "sk", "sl", "sr", "sv", "tr",
        "uk", "vi", "zh"
    ]

    // Fixed sizes for landscape mode.
    property int textAreaHeight: 250
    property int controlRowHeight: 50
    // In landscape, total frame height equals one text area plus two control rows.
    property int frameHeight: textAreaHeight + (2 * controlRowHeight)
    // In portrait, let the two frames fill available height.
    // GridLayout margins are 8 and rowSpacing is 12.
    property int effectiveFrameHeight: isLandscape ? frameHeight : ((height - (8*2 + 12)) / 2)

    SystemPalette {
        id: palette
        colorGroup: SystemPalette.Active
    }
    color: palette.window

    // Detect orientation.
    property bool isLandscape: width > height
    onWidthChanged: isLandscape = (width > height)
    onHeightChanged: isLandscape = (width > height)

    GridLayout {
        id: mainLayout
        anchors.fill: parent
        rowSpacing: 12
        columnSpacing: 12
        anchors.margins: 8
        // Two columns in landscape, one column in portrait.
        columns: isLandscape ? 2 : 1

        // --- SOURCE FRAME ---
        Frame {
            id: sourceFrame
            Layout.fillWidth: true
            Layout.preferredHeight: effectiveFrameHeight

            background: Rectangle {
                color: palette.base
                radius: 4
            }

            contentItem: Item {
                anchors.fill: parent

                // Top control row: ComboBox using the common model.
                ComboBox {
                    id: fromLangCombo
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 8
                    anchors.leftMargin: 8
                    height: controlRowHeight
                    width: 120
                    model: languages
                    // Default to "en" (index 7 in our array).
                    currentIndex: 7
                    palette: window.palette

                    background: Rectangle {
                        anchors.fill: parent
                        color: palette.mid
                        radius: 4
                    }

                    delegate: ItemDelegate {
                        width: fromLangCombo.width
                        contentItem: Text {
                            text: modelData
                            color: palette.text
                            font: fromLangCombo.font
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: palette.mid
                            anchors.fill: parent
                        }
                        highlighted: fromLangCombo.highlightedIndex === index
                    }

                    contentItem: Text {
                        text: fromLangCombo.model[fromLangCombo.currentIndex]
                        anchors.centerIn: parent
                        color: palette.text
                        verticalAlignment: Text.AlignVCenter
                    }

                    popup: Popup {
                        y: fromLangCombo.height
                        width: fromLangCombo.width
                        implicitHeight: contentItem.implicitHeight
                        padding: 0
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: fromLangCombo.popup.visible ? fromLangCombo.delegateModel : null
                            currentIndex: fromLangCombo.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator { }
                        }
                        background: Rectangle {
                            radius: 4
                        }
                    }
                }

                // Middle area: ScrollView wrapping the source TextArea.
                ScrollView {
                    id: sourceScrollView
                    anchors.top: fromLangCombo.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: isLandscape ? textAreaHeight : (effectiveFrameHeight - 2 * controlRowHeight)

                    TextArea {
                        id: sourceText
                        width: sourceScrollView.width
                        height: sourceScrollView.height
                        placeholderText: qsTr("Enter text to translate...")
                        wrapMode: TextEdit.Wrap
                        placeholderTextColor: palette.placeholderText
                        color: palette.text
                        background: null
                        readOnly: false
                        clip: true
                    }
                }

                // Bottom row: Contains a Paste button and the Translate button.
                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 8
                    anchors.leftMargin: 8
                    anchors.bottomMargin: 2
                    height: controlRowHeight

                    // Paste button.
                    Button {
                        id: pasteButton
                        width: controlRowHeight
                        height: controlRowHeight
                        icon.name: "edit-paste"
                        icon.color: "transparent"
                        background: Rectangle {
                            anchors.fill: parent
                            color: palette.button
                            radius: 4
                        }
                        onClicked: {
                            sourceText.paste()
                        }
                    }

                    // Spacer.
                    Item { Layout.fillWidth: true }

                    // Translate button.
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
                        onClicked: {
                            if (sourceText.text.trim() === "") return;
                            const fromLang = fromLangCombo.currentText;
                            const toLang   = toLangCombo.currentText;
                            const langPair = fromLang + toLang;
                            const result = translationBridge.translate(sourceText.text, langPair);
                            resultText.text = result;
                        }
                    }
                }
            }
        }

        // --- RESULT FRAME ---
        Frame {
            id: resultFrame
            Layout.fillWidth: true
            Layout.preferredHeight: effectiveFrameHeight

            background: Rectangle {
                color: palette.base
                radius: 4
            }

            contentItem: Item {
                anchors.fill: parent

                // Top control row: ComboBox using the common model.
                ComboBox {
                    id: toLangCombo
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 8
                    anchors.leftMargin: 8
                    height: controlRowHeight
                    width: 120
                    model: languages
                    // Default to "de" (index 5 in our array).
                    currentIndex: 5

                    background: Rectangle {
                        anchors.fill: parent
                        color: palette.mid
                        radius: 4
                    }

                    contentItem: Text {
                        text: toLangCombo.model[toLangCombo.currentIndex]
                        anchors.centerIn: parent
                        color: palette.text
                        verticalAlignment: Text.AlignVCenter
                    }

                    delegate: ItemDelegate {
                        width: toLangCombo.width
                        contentItem: Text {
                            text: modelData
                            color: palette.text
                            font: toLangCombo.font
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: palette.mid
                            anchors.fill: parent
                        }
                        highlighted: toLangCombo.highlightedIndex === index
                    }

                    popup: Popup {
                        y: toLangCombo.height
                        width: toLangCombo.width
                        implicitHeight: contentItem.implicitHeight
                        padding: 0
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: toLangCombo.popup.visible ? toLangCombo.delegateModel : null
                            currentIndex: toLangCombo.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator { }
                        }
                        background: Rectangle {
                            radius: 4
                        }
                    }
                }

                // Middle area: ScrollView wrapping the result TextArea.
                ScrollView {
                    id: resultScrollView
                    anchors.top: toLangCombo.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: isLandscape ? textAreaHeight : (effectiveFrameHeight - 2 * controlRowHeight)
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

                // Bottom row: Contains a Copy button.
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
                        width: controlRowHeight
                        height: controlRowHeight
                        background: Rectangle {
                            anchors.fill: parent
                            color: palette.button
                            radius: 4
                        }
                        icon.name: "edit-copy"
                        icon.color: "transparent"
                        onClicked: {
                            resultText.copy()
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 480
    height: 640
    visible: true
    title: qsTr("LocalTranslate")

    // Fixed sizes for our UI parts.
    property int textAreaHeight: 150
    property int controlRowHeight: 40
    // Total frame height equals one text area plus two control rows.
    property int frameHeight: textAreaHeight + (2 * controlRowHeight)

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
            Layout.preferredHeight: frameHeight

            background: Rectangle {
                color: palette.base
                radius: 4
            }


            contentItem: Item {
                anchors.fill: parent

                // Top control row: fixed-size ComboBox with margins.
                ComboBox {
                    id: fromLangCombo
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 8
                    anchors.leftMargin: 8
                    height: controlRowHeight
                    width: 120
                    model: ["en", "de", "fr", "es"]
                    currentIndex: 0
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
                        font.pixelSize: 16
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
                    height: window.textAreaHeight

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

                // Bottom row: Translate button aligned to the right with margins.
                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.bottomMargin: 8
                    height: controlRowHeight

                    // Spacer to push the button to the right.
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
                        onClicked: {
                            const fromLang = fromLangCombo.currentText
                            const toLang   = toLangCombo.currentText
                            const langPair = fromLang + toLang  // e.g. "ende" or "deen"
                            const result = translationBridge.translate(sourceText.text, langPair)
                            resultText.text = result
                        }
                    }

                }
            }
        }

        // --- RESULT FRAME ---
        Frame {
            id: resultFrame
            Layout.fillWidth: true
            Layout.preferredHeight: frameHeight

            background: Rectangle {
                color: palette.base
                radius: 4
            }

            contentItem: Item {
                anchors.fill: parent

                // Top control row: fixed-size ComboBox with margins.
                ComboBox {
                    id: toLangCombo
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 8
                    anchors.leftMargin: 8
                    height: controlRowHeight
                    width: 120   // fixed width so it doesn’t expand
                    model: ["en", "de", "fr", "es", "ja"]
                    currentIndex: 1

                    background: Rectangle {
                        anchors.fill: parent
                        color: palette.mid
                        radius: 4
                    }

                    contentItem: Text {
                        text: toLangCombo.model[toLangCombo.currentIndex]
                        anchors.centerIn: parent
                        color: palette.text
                        font.pixelSize: 14
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
                    height: window.textAreaHeight

                    TextArea {
                        id: resultText
                        width: resultScrollView.width
                        height: resultScrollView.height
                        placeholderText: qsTr("Translation will appear here")
                        placeholderTextColor: palette.placeholderText
                        wrapMode: TextEdit.Wrap
                        color: palette.text
                        background: null
                        readOnly: true
                        clip: true
                    }
                }

                // Bottom dummy row to match the overall frame height.
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: controlRowHeight
                    color: "transparent"
                }
            }
        }
    }
}

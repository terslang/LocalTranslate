// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.FluentWinUI3

ApplicationWindow {
    id: window
    width: 720 / 1.618
    height: 720
    visible: true
    title: qsTr("LocalTranslate")

    Settings {
        id: generalSettings
        category: "General"     // casing is important here

        property alias windowWidth: window.width
        property alias windowHeight: window.height

        property string fromLangCode
        property string toLangCode
    }

    Component.onCompleted: {
        sourceText.forceActiveFocus();      // focus on source text as soon as app launches
    }

    // The original array of objects
    readonly property var languages: translationBridge.languages

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

        let result = translationBridge.translate(sourceText.text, langPair)
        resultText.text = result
    }

    function clearText() {
        sourceText.clear()
        resultText.clear()
        sourceText.forceActiveFocus()
    }

    Shortcut {
        sequences: ["Ctrl+Enter", "Ctrl+Return"]
        context: Qt.ApplicationShortcut
        onActivated: window.doTranslate()
    }

    Shortcut {
        // Pressing Ctrl+D will clear source and release text and focuses on the source text
        sequences: ["Ctrl+D"]
        context: Qt.ApplicationShortcut
        onActivated: window.clearText()
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

                    Component.onCompleted: {
                        const langCode = generalSettings.fromLangCode || "en"
                        currentIndex = window.sortedLanguages.findIndex(
                                    lang => lang.code === langCode)

                        // set the lang in settings too
                        generalSettings.fromLangCode = langCode
                    }

                    onActivated: (index) => {
                        generalSettings.fromLangCode = model[currentIndex].code
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

                // Update settings too
                generalSettings.fromLangCode = sortedLanguages[fromLangCombo.currentIndex].code
                generalSettings.toLangCode = sortedLanguages[toLangCombo.currentIndex].code
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

                    Component.onCompleted: {
                        const langCode = generalSettings.toLangCode || "de"
                        currentIndex = window.sortedLanguages.findIndex(
                                    lang => lang.code === langCode)

                        // set the lang in settings too
                        generalSettings.toLangCode = langCode
                    }

                    onActivated: (index) => {
                        generalSettings.toLangCode = model[currentIndex].code
                        // Clear the existing result
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

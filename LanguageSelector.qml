// SPDX-License-Identifier: GPL-3.0-only

// Lets the delegate bind to the `selector` id of the enclosing component.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Controls.FluentWinUI3

// A language ComboBox that surfaces pinned and recently-used languages above
// the rest of the list, so frequently-used languages don't have to be hunted
// for in the full alphabetical list.
//
// The list is built from three groups, and every language appears in exactly
// one of them:
//
//   1. Pinned     - pinned by the user, always visible
//   2. Recent     - last few used, excluding pinned and the current selection
//   3. All other  - the remainder, collapsed by default
//
// Pins and recents are owned by the caller (persisted in Settings) and are
// per-selector: the source and target selectors keep separate lists, because
// translating *from* many unfamiliar languages *into* a couple of familiar
// ones is a common pattern, and a shared list would clutter both ends.
ComboBox {
    id: selector

    // Full alphabetical list of {code, name} objects.
    required property var allLanguages

    // Pinned language codes, in no particular order.
    property var pinnedCodes: []

    // Recently-used language codes, most recent first.
    property var recentCodes: []

    // Emitted when the user pins/unpins a language. The caller persists it.
    signal pinToggled(string code)

    textRole: "name"
    valueRole: "code"

    // Editable so the list can be narrowed by typing. The field is not a free
    // text input - it only ever filters - so it shows the selected language
    // when idle and is cleared for typing as soon as the popup opens.
    editable: true
    selectTextByMouse: true


    // `aboutToShow`/`aboutToHide` belong to the popup, not the ComboBox.
    Connections {
        target: selector.popup

        function onAboutToShow() {
            // Each time the popup opens: no filter and nothing expanded. The
            // edit field is focused with its text selected so that typing
            // starts filtering straight away, without a click into the field.
            selector.filter = ""
            selector.otherExpanded = false
            selector.focusEditField()
        }

        function onAboutToHide() {
            selector.filter = ""
            selector.resetEditText()
        }
    }

    // Typing narrows the list; the text is a filter, never a new language.
    //
    // The filter is driven from the edit field's own text rather than from
    // `onEditTextChanged`, because rebuilding the model moves `currentIndex`
    // and an editable ComboBox writes the new current row's name back into
    // `editText` - feeding that back would overwrite the filter with a
    // language name and match everything again. `displayText` is what the
    // field shows when idle, so comparing against it distinguishes a real
    // keystroke from that write-back.
    Connections {
        target: selector.editField
        enabled: selector.editField !== null

        function onTextEdited() {
            selector.filter = selector.editField.text
        }
    }

    readonly property int maxRecent: 3

    // What the user has typed to narrow the list. While it is non-empty the
    // grouping is set aside and the popup shows plain search results, because
    // "pinned" and "recent" are ways of not having to search.
    property string filter: ""
    readonly property bool searching: filter.length > 0

    // Matches on the language name and on the code, so both "ger" and "de"
    // find German. Case-insensitive, and matched anywhere in the name so
    // "nese" still finds Japanese.
    function matchesFilter(lang) {
        const needle = filter.toLowerCase()
        return lang.name.toLowerCase().includes(needle)
                || lang.code.toLowerCase().startsWith(needle)
    }

    readonly property var matchingLanguages: allLanguages.filter(
                                                 lang => matchesFilter(lang))

    function isPinned(code) {
        return pinnedCodes.includes(code)
    }

    // Group 1: pinned, in the same alphabetical order as the full list.
    readonly property var pinnedLanguages: allLanguages.filter(
                                               lang => isPinned(lang.code))

    // Group 2: recents, most-recent-first. Pinned languages are already shown
    // above, and the current selection is visible on the closed control, so
    // neither earns a slot here.
    readonly property var recentLanguages: recentCodes.filter(
                                               code => !isPinned(code)
                                               && code !== selectedCode).slice(
                                               0, maxRecent).map(
                                               code => allLanguages.find(
                                                   lang => lang.code === code)).filter(
                                               lang => lang !== undefined)

    // Group 3: everything not already listed above.
    readonly property var otherLanguages: allLanguages.filter(
                                              lang => !isPinned(lang.code)
                                              && !recentLanguages.some(
                                                  recent => recent.code === lang.code))

    // Grouping only earns its keep once there is something to lift to the top.
    readonly property bool grouped: pinnedLanguages.length > 0
                                    || recentLanguages.length > 0

    // Whether the "All other" group is expanded. It always starts collapsed:
    // an expanded list of every language is taller than the window, which
    // leaves the style no room to drop the popup below the control. Typing
    // filters the whole list, so a collapsed group no longer hides anything -
    // searching, not scrolling, is how you reach an unlisted language.
    property bool otherExpanded: false
    readonly property bool showOther: !grouped || otherExpanded || searching

    function toggleOther() {
        otherExpanded = !otherExpanded
    }

    // Rows are tagged so one delegate can render both languages and the
    // "All other" disclosure row. Everything a row needs to draw itself is
    // baked in here, so the delegate only ever reads its own modelData - it
    // cannot reach back into this component, which is not in scope for a
    // delegate loaded from compiled resources.
    // Handed to every row so the delegate has a way to call back. The
    // delegate cannot see this component's id - it is out of scope when the
    // component is loaded from compiled resources - but it can reach this
    // through the row it was given.
    readonly property var rowActions: ({
        togglePin: code => selector.pinToggled(code),
        toggleOther: () => selector.toggleOther()
    })

    readonly property var rows: {
        const languageRow = (lang, group, divider) => ({
            kind: "lang",
            lang: lang,
            name: lang.name,
            code: lang.code,
            group: group,
            pinned: isPinned(lang.code),
            divider: divider,
            actions: rowActions
        })

        // While searching, show the matches as one flat list: the groups only
        // help when you are browsing, and splitting a handful of results
        // across three headings makes them harder to scan, not easier.
        if (searching)
            return matchingLanguages.map(lang => languageRow(lang, "match", false))

        if (!grouped)
            return allLanguages.map(lang => languageRow(lang, "other", false))

        let out = pinnedLanguages.map(lang => languageRow(lang, "pinned", false))

        recentLanguages.forEach((lang, i) => out.push(
                                    languageRow(lang, "recent",
                                                i === 0 && out.length > 0)))

        out.push({
            kind: "toggle",
            lang: null,
            name: (showOther ? "▾ " : "▸ ")
                  + qsTr("All other (%1)").arg(otherLanguages.length),
            code: "",
            group: "toggle",
            pinned: false,
            divider: out.length > 0,
            actions: rowActions
        })

        if (showOther)
            otherLanguages.forEach(lang => out.push(
                                       languageRow(lang, "other", false)))

        return out
    }

    model: rows

    // The selected language, tracked by code: a language's row index shifts
    // whenever pins, recents, or the collapsed state change, so the code is
    // the only stable identifier. This is the single source of truth for the
    // selection - `currentIndex` is derived from it, never the other way
    // round, which is what keeps the model rebuild from feeding back into the
    // selection.
    property string selectedCode: ""

    function selectByCode(code) {
        if (code)
            selectedCode = code
    }

    readonly property var currentLanguage: allLanguages.find(
                                               lang => lang.code === selectedCode) ?? null
    readonly property string currentName: currentLanguage ? currentLanguage.name : ""
    displayText: currentName

    // An editable ComboBox keeps whatever was typed in its field, so put the
    // selected language back once the filtering is over. This runs on close
    // and whenever the selection changes, which also covers the popup being
    // dismissed without a choice.
    // The editable ComboBox's contentItem is the TextField holding `editText`.
    // It is declared as a plain Item, so it is reached through a typed alias
    // rather than by calling straight through the untyped property.
    readonly property TextInput editField: contentItem as TextInput

    function focusEditField() {
        if (!editField)
            return
        editField.forceActiveFocus()
        editField.selectAll()
    }

    function resetEditText() {
        if (editText !== currentName)
            editText = currentName
    }
    onCurrentNameChanged: resetEditText()

    // Keep the highlighted row in step with the selected language. Assigning
    // currentIndex has no effect on `selectedCode`, so this cannot loop.
    readonly property int selectedRow: rows.findIndex(row => row.kind === "lang"
                                                      && row.lang.code === selectedCode)
    onSelectedRowChanged: if (selectedRow >= 0) currentIndex = selectedRow

    // Emitted when the user picks an actual language, as opposed to clicking
    // the "All other" disclosure row. Callers should use this instead of
    // `activated`, which also fires for the disclosure row.
    signal languageSelected(string code)

    Component.onCompleted: {
        if (selectedRow >= 0)
            currentIndex = selectedRow
        resetEditText()
    }

    // The disclosure row is not a language: activating it expands the group
    // and restores the previous selection rather than selecting the row.
    // Connections is used so that a caller assigning `onActivated` cannot
    // accidentally replace this handler.
    Connections {
        target: selector
        function onActivated(index) {
            const row = selector.rows[index]
            if (!row)
                return
            if (row.kind === "toggle") {
                selector.toggleOther()
                // The disclosure row is not a selection; put the highlight
                // back on the selected language.
                if (selector.selectedRow >= 0)
                    selector.currentIndex = selector.selectedRow
            } else {
                selector.selectedCode = row.lang.code
                selector.languageSelected(row.lang.code)
            }
        }
    }

    delegate: ItemDelegate {
        id: langDelegate

        required property int index
        required property var modelData

        // The delegate reads only its own row data plus the view it lives in.
        // The enclosing component's id is not in scope for a delegate loaded
        // from compiled resources, so reaching outward would leave it null.
        readonly property var view: ListView.view
        readonly property bool isToggle: modelData.kind === "toggle"

        // The disclosure row is a control, not a choice. ItemDelegate's own
        // click would reach the ComboBox and close the popup, so the row
        // swallows the click and expands the group in place instead.
        onClicked: if (isToggle) modelData.actions.toggleOther()

        width: view ? view.width : implicitWidth
        highlighted: ListView.isCurrentItem

        // Divider above the first row of each group. The fade on the recent
        // rows is a hint, not a boundary - the line is what actually separates
        // the groups - so it gets real space around it and a colour that stays
        // visible against the popup background, which `palette.mid` did not.
        topPadding: modelData.divider ? 9 : 4

        Rectangle {
            visible: langDelegate.modelData.divider
            anchors.top: parent.top
            anchors.topMargin: 4
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.right: parent.right
            anchors.rightMargin: 2
            height: 1
            color: Qt.alpha(langDelegate.palette.text, 0.25)
        }

        contentItem: Item {
            implicitHeight: langLabel.implicitHeight

            Text {
                id: langLabel
                anchors.left: parent.left
                anchors.right: pinButton.left
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: langDelegate.modelData.name
                color: langDelegate.palette.text
                // The recent group is a convenience, not a list the user
                // curated, so it sits visually below the pinned rows.
                opacity: langDelegate.isToggle
                         ? 0.7
                         : (langDelegate.modelData.group === "recent" ? 0.62 : 1.0)
                font: langDelegate.font
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            // Pin toggle. Clicking it pins/unpins without closing the popup,
            // so several languages can be pinned in one go.
            AbstractButton {
                id: pinButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 20
                implicitHeight: 20
                visible: !langDelegate.isToggle

                // Unpinned languages only reveal the pin on hover, to keep the
                // list from looking like a wall of icons.
                opacity: langDelegate.modelData.pinned
                         ? 1.0
                         : (hovered || langDelegate.hovered ? 0.55 : 0.0)

                onClicked: langDelegate.modelData.actions.togglePin(
                               langDelegate.modelData.code)

                ToolTip.visible: hovered
                ToolTip.text: langDelegate.modelData.pinned ? qsTr("Unpin language")
                                                            : qsTr("Pin language")
                ToolTip.delay: 300

                // The pin is drawn rather than set as text: the pushpin
                // codepoints are either missing from the UI font (U+1F588
                // renders as tofu) or are colour emoji that ignore the
                // palette (U+1F4CC), and which of those applies depends on
                // the fonts installed. A shape always renders and always
                // takes the text colour.
                contentItem: Item {
                    id: pinIcon

                    // Filled when pinned, outline when not.
                    readonly property bool filled: langDelegate.modelData.pinned
                    readonly property color stroke: langDelegate.palette.text

                    Shape {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        preferredRendererType: Shape.CurveRenderer

                        // A pin seen from the side: round head, tapering body,
                        // and a needle pointing down-left.
                        ShapePath {
                            fillColor: pinIcon.filled ? pinIcon.stroke : "transparent"
                            strokeColor: pinIcon.stroke
                            strokeWidth: 1.2
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin

                            // Head and body.
                            PathAngleArc {
                                centerX: 8.5; centerY: 5.5
                                radiusX: 4.2; radiusY: 4.2
                                startAngle: 20; sweepAngle: 300
                            }
                        }

                        // The needle, always a stroke so the pin reads as a pin
                        // even when the head is hollow.
                        ShapePath {
                            strokeColor: pinIcon.stroke
                            strokeWidth: 1.4
                            capStyle: ShapePath.RoundCap
                            startX: 6.2; startY: 8.6
                            PathLine { x: 2.2; y: 12.8 }
                        }
                    }
                }
            }
        }
    }
}

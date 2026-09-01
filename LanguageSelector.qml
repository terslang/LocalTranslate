// SPDX-License-Identifier: GPL-3.0-only

// Lets the delegate bind to the `selector` id of the enclosing component.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Window
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

    readonly property int maxRecent: 3

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

    // Whether the "All other" group is expanded. It starts collapsed, but
    // opens on its own while it holds the current selection, so opening the
    // popup never hides where you are. The user can still collapse it from
    // there, hence a tri-state rather than a plain boolean: "auto" defers to
    // the selection, while an explicit choice wins until the selection moves
    // back out of the group.
    property string otherExpansion: "auto"   // "auto" | "expanded" | "collapsed"
    readonly property bool otherHoldsSelection: otherLanguages.some(
                                                    lang => lang.code === selectedCode)
    readonly property bool showOther: {
        if (!grouped)
            return true
        if (otherExpansion !== "auto")
            return otherExpansion === "expanded"
        return otherHoldsSelection
    }

    function toggleOther() {
        otherExpansion = showOther ? "collapsed" : "expanded"
    }

    // Once the selection leaves the group, drop back to automatic behaviour so
    // the next popup starts collapsed again.
    onOtherHoldsSelectionChanged: if (!otherHoldsSelection) otherExpansion = "auto"

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
    displayText: currentLanguage ? currentLanguage.name : ""

    // Keep the highlighted row in step with the selected language. Assigning
    // currentIndex has no effect on `selectedCode`, so this cannot loop.
    readonly property int selectedRow: rows.findIndex(row => row.kind === "lang"
                                                      && row.lang.code === selectedCode)
    onSelectedRowChanged: if (selectedRow >= 0) currentIndex = selectedRow

    // Emitted when the user picks an actual language, as opposed to clicking
    // the "All other" disclosure row. Callers should use this instead of
    // `activated`, which also fires for the disclosure row.
    signal languageSelected(string code)

    Component.onCompleted: if (selectedRow >= 0) currentIndex = selectedRow

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

    // The list can grow tall enough that the style would flip it above the
    // control to fit, which covers the app header. The chevron on the control
    // points down, so the popup always opens down: pin it below the control and
    // cap its height at the room left underneath, letting it scroll instead.
    popup.y: selector.height

    // Room between the bottom of the control and the bottom of the window.
    // Guarded because the selector has no window until it is shown, and
    // because a very short window would otherwise ask for a negative height.
    readonly property real roomBelow: {
        if (!selector.Window.window)
            return 0
        const top = selector.mapToItem(null, 0, selector.height).y
        return Math.max(0, selector.Window.height - top - 8)
    }
    popup.height: roomBelow > 0 ? Math.min(popup.implicitHeight, roomBelow)
                                : popup.implicitHeight

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

        // Divider above the first row of each group.
        topPadding: modelData.divider ? 5 : 4

        Rectangle {
            visible: langDelegate.modelData.divider
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: langDelegate.palette.mid
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

                contentItem: Text {
                    // U+1F588 is a text-presentation pushpin, so it inherits
                    // `color` instead of rendering as a colour emoji the way
                    // U+1F4CC would. Unpinned rows use the same glyph and lean
                    // on opacity alone, so the icon never shifts position.
                    text: "\u{1F588}\u{FE0E}"
                    color: langDelegate.palette.text
                    font.pixelSize: langDelegate.font.pixelSize + 2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// Lets the delegate bind to the `selector` id of the enclosing component.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.FluentWinUI3

// A language ComboBox that surfaces pinned and recently-used languages above
// the rest of the list, so frequently-used languages don't have to be hunted
// for in the full alphabetical list.
//
// The list is built from three groups, and every language appears in exactly
// one of them:
//
//   1. Pinned     - starred by the user, always visible
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

    // Emitted when the user stars/unstars a language. The caller persists it.
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
    // "All other" disclosure row.
    readonly property var rows: {
        if (!grouped)
            return allLanguages.map(lang => ({ kind: "lang", lang: lang, divider: false }))

        let out = pinnedLanguages.map(lang => ({ kind: "lang", lang: lang, divider: false }))

        recentLanguages.forEach((lang, i) => out.push({
            kind: "lang",
            lang: lang,
            divider: i === 0 && out.length > 0
        }))

        out.push({ kind: "toggle", lang: null, divider: out.length > 0 })

        if (showOther)
            otherLanguages.forEach(lang => out.push({
                kind: "lang", lang: lang, divider: false
            }))

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
    Component.onCompleted: if (selectedRow >= 0) currentIndex = selectedRow

    // Emitted when the user picks an actual language, as opposed to clicking
    // the "All other" disclosure row. Callers should use this instead of
    // `activated`, which also fires for the disclosure row.
    signal languageSelected(string code)

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

        // The enclosing selector, pulled in explicitly so the delegate can
        // reach its pin state.
        readonly property LanguageSelector owner: selector

        readonly property bool isToggle: modelData.kind === "toggle"
        readonly property var lang: modelData.lang
        readonly property bool pinned: !isToggle && owner.isPinned(lang.code)

        width: owner.width
        highlighted: owner.highlightedIndex === index

        // Divider above the first row of each group.
        topPadding: modelData.divider ? 5 : 4

        // The disclosure row expands the list rather than selecting anything.
        onClicked: if (isToggle) owner.toggleOther()

        Rectangle {
            visible: langDelegate.modelData.divider
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: langDelegate.owner.palette.mid
        }

        contentItem: Item {
            implicitHeight: langLabel.implicitHeight

            Text {
                id: langLabel
                anchors.left: parent.left
                anchors.right: pinButton.left
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: langDelegate.isToggle
                      ? (langDelegate.owner.showOther ? "▾ " : "▸ ")
                        + qsTr("All other (%1)").arg(langDelegate.owner.otherLanguages.length)
                      : langDelegate.lang.name
                color: langDelegate.palette.text
                opacity: langDelegate.isToggle ? 0.7 : 1.0
                font: langDelegate.owner.font
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            // Star toggle. Clicking it pins/unpins without closing the popup,
            // so several languages can be pinned in one go.
            AbstractButton {
                id: pinButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 20
                implicitHeight: 20
                visible: !langDelegate.isToggle

                // Unpinned languages only reveal the star on hover, to keep the
                // list from looking like a wall of icons.
                opacity: langDelegate.pinned ? 1.0
                                             : (hovered || langDelegate.hovered ? 0.55 : 0.0)

                onClicked: langDelegate.owner.pinToggled(langDelegate.lang.code)

                ToolTip.visible: hovered
                ToolTip.text: langDelegate.pinned ? qsTr("Unpin language")
                                                  : qsTr("Pin language")
                ToolTip.delay: 300

                contentItem: Text {
                    text: langDelegate.pinned ? "★" : "☆"
                    color: langDelegate.palette.text
                    font.pixelSize: langDelegate.owner.font.pixelSize + 2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}

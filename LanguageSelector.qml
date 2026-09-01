// SPDX-License-Identifier: GPL-3.0-only

// Lets the delegate bind to the `selector` id of the enclosing component.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.FluentWinUI3

// A language ComboBox that surfaces pinned languages in a section above the
// rest of the list, so frequently-used languages don't have to be hunted for
// in the full alphabetical list.
//
// Pins are owned by the caller (persisted in Settings) and are per-selector:
// the source and target selectors keep separate pin lists, because translating
// *from* many unfamiliar languages *into* a couple of familiar ones is a common
// pattern, and a shared list would clutter both ends.
ComboBox {
    id: selector

    // Full alphabetical list of {code, name} objects.
    required property var allLanguages

    // Pinned language codes, in no particular order.
    property var pinnedCodes: []

    // Emitted when the user stars/unstars a language. The caller persists it.
    signal pinToggled(string code)

    textRole: "name"
    valueRole: "code"

    readonly property bool hasPins: pinnedCodes.length > 0

    // Pinned entries first (alphabetically), then everything else. Each
    // language appears exactly once, so an index is never ambiguous.
    readonly property var pinnedLanguages: allLanguages.filter(
                                               lang => pinnedCodes.includes(lang.code))
    readonly property var otherLanguages: allLanguages.filter(
                                              lang => !pinnedCodes.includes(lang.code))

    model: hasPins ? pinnedLanguages.concat(otherLanguages) : allLanguages

    // The index of the first entry that is not pinned, so the delegate knows
    // where to draw the divider. -1 when there is nothing to separate.
    readonly property int firstUnpinnedIndex: hasPins ? pinnedLanguages.length : -1

    // Select by language code rather than by index. The index of a language
    // shifts whenever the pinned set changes, so the code is the only stable
    // identifier to select by.
    function selectByCode(code) {
        const index = model.findIndex(lang => lang.code === code)
        if (index >= 0)
            currentIndex = index
    }

    function isPinned(code) {
        return pinnedCodes.includes(code)
    }

    // Re-derive the selection after the model is rebuilt, otherwise
    // currentIndex would keep pointing at whatever language now occupies that
    // position.
    onModelChanged: selectByCode(currentValue)

    delegate: ItemDelegate {
        id: langDelegate

        required property int index
        required property var modelData

        // The enclosing selector, pulled in explicitly so the delegate can
        // reach its pin state.
        readonly property LanguageSelector owner: selector

        width: owner.width
        highlighted: owner.highlightedIndex === index

        // Divider between the pinned section and the rest of the list.
        topPadding: showDivider ? 5 : 4
        readonly property bool showDivider: index === owner.firstUnpinnedIndex
                                            && index > 0
        readonly property bool pinned: owner.isPinned(modelData.code)

        Rectangle {
            visible: langDelegate.showDivider
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
                text: langDelegate.modelData.name
                color: langDelegate.palette.text
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

                // Unpinned languages only reveal the star on hover, to keep the
                // list from looking like a wall of icons.
                opacity: langDelegate.pinned ? 1.0
                                             : (hovered || langDelegate.hovered ? 0.55 : 0.0)

                onClicked: langDelegate.owner.pinToggled(langDelegate.modelData.code)

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

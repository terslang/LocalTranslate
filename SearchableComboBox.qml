import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ComboBox {
    id: combo

    property var imodel: []

    property var filteredModel: []

    property string filterText: ""

    model: filteredModel

    popup: Popup {
        id: comboPopup
        y: combo.height
        width: combo.width

        onVisibleChanged: {
            if (visible) filterField.forceActiveFocus()
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            spacing: 4

            // --- Filter field ---
            TextField {
                id: filterField
                placeholderText: qsTr("Filter…")
                Layout.fillWidth: true

                onTextChanged: combo.filterText = text

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Down) {
                        listView.currentIndex = Math.min(listView.currentIndex + 1, listView.count - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        listView.currentIndex = Math.max(listView.currentIndex - 1, 0)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (listView.currentIndex >= 0 && listView.currentIndex < listView.count) {
                            combo.currentIndex = listView.currentIndex
                            combo.popup.close()
                        }
                        event.accepted = true
                    }
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 200)

                clip: true
                highlightFollowsCurrentItem: true
                model: combo.delegateModel
                focus: true

                ScrollIndicator.vertical: ScrollIndicator { }
            }
        }
    }

    delegate: ItemDelegate {
        width: combo.width
        text: modelData

        onClicked: {
            combo.currentIndex = index
            combo.popup.close()
        }
    }

    contentItem: Label {
        text: {
            if (combo.currentIndex < 0 || combo.currentIndex >= combo.model.length) return ""
            return combo.model[combo.currentIndex]
        }
        anchors.centerIn: parent
        horizontalAlignment: Label.AlignLeft
        verticalAlignment: Label.AlignVCenter
        elide: Text.ElideRight
    }

    onImodelChanged: recalcFilter()
    onFilterTextChanged: recalcFilter()

    function recalcFilter() {
        if (!imodel || imodel.length === 0) {
            filteredModel = []
            return
        }
        let typed = filterText.trim().toLowerCase()
        if (typed.length === 0) {
            filteredModel = imodel
        } else {
            filteredModel = imodel.filter(function(item) {
                return item.toLowerCase().includes(typed)
            })
        }
    }

    // Default size
    width: 200
    height: 32

    background: Rectangle {
        anchors.fill: parent
        radius: 4
        color: combo.palette.base
    }
}

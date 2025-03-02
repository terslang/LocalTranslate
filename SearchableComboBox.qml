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
        y: combo.height - 1
        width: combo.width
        padding: 1

        onVisibleChanged: {
            if (visible) {
                // Force the filter field to take focus as soon as the popup appears.
                filterConditionText.forceActiveFocus();
            }
        }

        contentItem: Item {
            anchors.fill: parent

            TextArea {
                id: filterConditionText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 35
                onTextChanged: combo.filterText = text

                // Prevent multi-line input
                wrapMode: TextEdit.NoWrap

                placeholderText: qsTr("Filter…")
                placeholderTextColor: parent.palette.placeholderText
                color: parent.palette.text
                selectionColor: parent.palette.highlight
                selectedTextColor: parent.palette.highlightedText
                focus: true

                background: Rectangle {
                    anchors.fill: parent
                    color: palette.base
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: combo.activeFocus ? palette.highlight : palette.mid
                }

                // Capture arrow keys & Enter
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
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: filterConditionText.bottom
                clip: true
                model: combo.delegateModel
                focus: true
                highlightFollowsCurrentItem: true
                height: Math.min(contentHeight, 350)

                ScrollIndicator.vertical: ScrollIndicator { }
            }
        }
    }


    delegate: ItemDelegate {
        width: combo.width

        contentItem: Text {
            text: modelData
            font.pointSize: 12
            verticalAlignment: Text.AlignVCenter
            color: palette.text
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 10
        }

        background: Rectangle {
            color: highlighted ? Qt.lighter(palette.base, 1.25) : palette.base
            anchors.fill: parent
        }

        highlighted: ListView.isCurrentItem

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                listView.currentIndex = index
            }

            onClicked: {
                listView.currentIndex = index
                combo.currentIndex = listView.currentIndex
                combo.popup.close()
            }
        }
    }

    contentItem: Text {
        text: {
            if (combo.currentIndex < 0 || combo.currentIndex >= combo.model.length) return ""
            return combo.model[combo.currentIndex]
        }
        color: palette.text
        anchors.centerIn: parent
        horizontalAlignment: Label.AlignLeft
        verticalAlignment: Label.AlignVCenter
        anchors.left: parent.left
        anchors.leftMargin: 8
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

    background: Rectangle {
        anchors.fill: parent
        color: palette.mid
        radius: 4
    }

    height: 40
}

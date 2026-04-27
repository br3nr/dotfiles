pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: popup
    color: "transparent"
    implicitWidth: 140
    implicitHeight: contentCol.implicitHeight + 16

    required property var barWindow
    required property Item anchorItem

    anchor.window: barWindow
    anchor.onAnchoring: {
        let pos = anchorItem.mapToItem(barWindow.contentItem, 0, 0);
        anchor.rect.x = pos.x + anchorItem.width - popup.implicitWidth;
        anchor.rect.y = barWindow.contentItem.height + 8;
    }

    // Delay the focus grab so the popup surface is fully mapped first
    property bool grabActive: false
    onVisibleChanged: {
        if (visible) {
            grabTimer.start();
        } else {
            grabActive = false;
            grabTimer.stop();
        }
    }
    Timer {
        id: grabTimer
        interval: 50
        onTriggered: popup.grabActive = true
    }

    HyprlandFocusGrab {
        active: popup.grabActive
        windows: [popup, popup.barWindow]
        onCleared: popup.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.card
        border.color: Theme.borderColor
        border.width: 1
        radius: 0
    }

    ColumnLayout {
        id: contentCol
        anchors {
            fill: parent
            margins: 8
        }
        spacing: 2

        Repeater {
            model: [
                { label: "lock", cmd: "hyprlock" },
                { label: "suspend", cmd: "systemctl suspend" },
                { label: "reboot", cmd: "systemctl reboot" },
                { label: "shutdown", cmd: "systemctl poweroff" },
                { label: "logout", cmd: "hyprctl dispatch exit" },
            ]

            delegate: Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                radius: Theme.itemRadius
                color: hoverArea.containsMouse ? Theme.secondary : "transparent"

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 6
                        verticalCenter: parent.verticalCenter
                    }
                    text: modelData.label
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textInactiveColor
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        popup.visible = false;
                        pwrProc.command = ["bash", "-c", modelData.cmd];
                        pwrProc.running = true;
                    }
                }
            }
        }
    }

    Process {
        id: pwrProc
    }
}

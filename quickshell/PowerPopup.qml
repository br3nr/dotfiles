pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: popup
    color: "transparent"
    width: 140
    height: contentCol.implicitHeight + 16

    required property var barWindow

    anchor.window: barWindow

    HyprlandFocusGrab {
        active: popup.visible
        windows: [popup, popup.barWindow]
        onCleared: popup.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.card
        border.color: Theme.borderColor
        border.width: 1
        radius: 4
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
                    color: (modelData.label === "shutdown" || modelData.label === "reboot")
                           ? Theme.textActiveColor : Theme.textInactiveColor
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

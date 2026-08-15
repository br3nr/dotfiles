pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: popup
    color: "transparent"
    implicitWidth: 320
    implicitHeight: Math.min(420, contentCol.implicitHeight + 16)

    required property var barWindow
    required property Item anchorItem
    property var themes: []
    property string errorText: ""

    anchor.window: barWindow
    anchor.onAnchoring: {
        let pos = anchorItem.mapToItem(barWindow.contentItem, 0, 0);
        anchor.rect.x = pos.x + anchorItem.width - popup.implicitWidth;
        anchor.rect.y = barWindow.contentItem.height + 8;
    }

    function reloadThemes(): void {
        errorText = "";
        listProc.running = true;
    }

    function wallpaperUrl(path): string {
        if (!path) return "";
        return "file://" + path.replace(/^\$HOME/, Quickshell.env("HOME"));
    }

    property bool grabActive: false
    onVisibleChanged: {
        if (visible) {
            reloadThemes();
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

    Process {
        id: listProc
        command: [Quickshell.env("HOME") + "/.config/theme/switch-theme.sh", "list-json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    popup.themes = JSON.parse(this.text);
                    popup.errorText = "";
                } catch (error) {
                    popup.themes = [];
                    popup.errorText = "could not read themes";
                }
            }
        }
    }

    Process {
        id: applyProc
        property string pendingTheme: ""
        command: [Quickshell.env("HOME") + "/.config/theme/switch-theme.sh", "apply", pendingTheme]
        onExited: exitCode => {
            if (exitCode === 0) {
                popup.visible = false;
            } else {
                popup.errorText = "could not apply " + pendingTheme;
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceRaised
        border.color: Theme.borderSubtle
        border.width: 1
    }

    ColumnLayout {
        id: contentCol
        anchors {
            fill: parent
            margins: 8
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "themes"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                renderType: Text.NativeRendering
            }

            Item { Layout.fillWidth: true }

            Text {
                text: popup.themes.length + " installed"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textMuted
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.borderSubtle
        }

        Text {
            Layout.fillWidth: true
            visible: popup.errorText !== ""
            text: popup.errorText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.error
            renderType: Text.NativeRendering
        }

        Repeater {
            model: popup.themes

            delegate: Rectangle {
                id: themeCard
                required property var modelData
                readonly property bool active: modelData.id === Theme.themeId
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                radius: Theme.itemRadius
                color: cardMouse.containsMouse ? Theme.stateHover : "transparent"
                border.width: active ? 1 : 0
                border.color: Theme.borderStrong

                RowLayout {
                    anchors {
                        fill: parent
                        margins: 6
                    }
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 116
                        Layout.fillHeight: true
                        color: themeCard.modelData.quickshell.surfaceBase
                        border.width: 1
                        border.color: themeCard.modelData.quickshell.borderSubtle
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: popup.wallpaperUrl(themeCard.modelData.wallpaper)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "#18000000"
                        }

                        Text {
                            anchors {
                                left: parent.left
                                bottom: parent.bottom
                                margins: 5
                            }
                            text: themeCard.active ? "active" : "preview"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: "white"
                            renderType: Text.NativeRendering
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: themeCard.modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                                renderType: Text.NativeRendering
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: themeCard.modelData.appearance
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.textMuted
                                renderType: Text.NativeRendering
                            }
                        }

                        Text {
                            text: themeCard.modelData.id
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textMuted
                            renderType: Text.NativeRendering
                        }

                        Row {
                            spacing: 4

                            Repeater {
                                model: [
                                    themeCard.modelData.quickshell.surfaceBase,
                                    themeCard.modelData.quickshell.surfaceRaised,
                                    themeCard.modelData.quickshell.accent,
                                    themeCard.modelData.quickshell.textMuted,
                                    themeCard.modelData.quickshell.textPrimary,
                                    themeCard.modelData.quickshell.success,
                                    themeCard.modelData.quickshell.error
                                ]

                                delegate: Rectangle {
                                    required property string modelData
                                    width: 14
                                    height: 14
                                    radius: Theme.itemRadius
                                    color: modelData
                                    border.width: 1
                                    border.color: Theme.borderSubtle
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: themeCard.active ? "currently applied" : "click to apply"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: themeCard.active ? Theme.success : Theme.textMuted
                            renderType: Text.NativeRendering
                        }
                    }
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: themeCard.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (themeCard.active || applyProc.running) return;
                        applyProc.pendingTheme = themeCard.modelData.id;
                        applyProc.running = true;
                    }
                }
            }
        }
    }
}

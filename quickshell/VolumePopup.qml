pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

PopupWindow {
    id: popup
    color: "transparent"
    implicitWidth: 240
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

    // Bind all sink nodes so their audio properties are available
    PwObjectTracker {
        id: sinkTracker
        objects: {
            let arr = [];
            for (let i = 0; i < Pipewire.nodes.values.length; i++) {
                let node = Pipewire.nodes.values[i];
                if (node.isSink && !node.isStream && node.audio)
                    arr.push(node);
            }
            if (Pipewire.defaultAudioSink)
                arr.push(Pipewire.defaultAudioSink);
            return arr;
        }
    }

    property var activePlayer: {
        let fallback = null;
        for (let i = 0; i < Mpris.players.values.length; i++) {
            let p = Mpris.players.values[i];
            if (p.trackTitle) {
                if (p.isPlaying) return p;
                if (!fallback) fallback = p;
            }
        }
        return fallback;
    }

    // Cache art URL so it doesn't flicker when metadata briefly nulls
    property string cachedArtUrl: ""
    onActivePlayerChanged: {
        if (activePlayer?.trackArtUrl)
            cachedArtUrl = activePlayer.trackArtUrl;
    }
    Connections {
        target: popup.activePlayer
        function onTrackArtUrlChanged() {
            if (popup.activePlayer?.trackArtUrl)
                popup.cachedArtUrl = popup.activePlayer.trackArtUrl;
        }
        function onTrackTitleChanged() {
            // New track — clear cache until new art arrives
            if (popup.activePlayer?.trackArtUrl)
                popup.cachedArtUrl = popup.activePlayer.trackArtUrl;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceRaised
        border.color: Theme.borderSubtle
        border.width: 1
        radius: 0
    }

    ColumnLayout {
        id: contentCol
        anchors {
            fill: parent
            margins: 8
        }
        spacing: 8

        // Now Playing section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: popup.activePlayer !== null

            // Album art + track info
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Album art
                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: Theme.itemRadius
                    color: Theme.surfaceOverlay
                    clip: true
                    visible: popup.cachedArtUrl !== ""

                    Image {
                        anchors.fill: parent
                        source: popup.cachedArtUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                }

                // Track info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: popup.activePlayer?.trackTitle ?? ""
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                        renderType: Text.NativeRendering
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: popup.activePlayer?.trackArtist ?? ""
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textMuted
                        renderType: Text.NativeRendering
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }

            // Playback controls
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }

                Text {
                    text: "prev"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: (popup.activePlayer?.canGoPrevious ?? false)
                           ? Theme.textMuted : Theme.textDisabled
                    renderType: Text.NativeRendering
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (popup.activePlayer?.canGoPrevious) popup.activePlayer.previous(); }
                    }
                }

                Text {
                    text: (popup.activePlayer?.isPlaying ?? false) ? "pause" : "play"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    renderType: Text.NativeRendering
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (popup.activePlayer?.canTogglePlaying) popup.activePlayer.togglePlaying(); }
                    }
                }

                Text {
                    text: "next"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: (popup.activePlayer?.canGoNext ?? false)
                           ? Theme.textMuted : Theme.textDisabled
                    renderType: Text.NativeRendering
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (popup.activePlayer?.canGoNext) popup.activePlayer.next(); }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Separator after now playing
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.borderSubtle
            }
        }

        // Volume label + value
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "vol"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textPrimary
                renderType: Text.NativeRendering
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Pipewire.defaultAudioSink?.audio
                      ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%"
                      : "—"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textMuted
                renderType: Text.NativeRendering
            }
        }

        // Volume slider
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 12

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 2
                color: Theme.surfaceOverlay
                radius: 1
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Pipewire.defaultAudioSink?.audio
                       ? parent.width * Math.min(Pipewire.defaultAudioSink.audio.volume, 1.0)
                       : 0
                height: 2
                color: Theme.accent
                radius: 1
            }

            Rectangle {
                id: sliderHandle
                anchors.verticalCenter: parent.verticalCenter
                x: Pipewire.defaultAudioSink?.audio
                   ? parent.width * Math.min(Pipewire.defaultAudioSink.audio.volume, 1.0) - width / 2
                   : -width / 2
                width: 8
                height: 8
                radius: 4
                color: Theme.accent
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -4
                anchors.bottomMargin: -4
                onPressed: function(mouse) { updateVolume(mouse.x); }
                onPositionChanged: function(mouse) { updateVolume(mouse.x); }

                function updateVolume(mouseX) {
                    if (!Pipewire.defaultAudioSink?.audio) return;
                    let vol = Math.max(0, Math.min(1, mouseX / parent.width));
                    Pipewire.defaultAudioSink.audio.volume = vol;
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.borderSubtle
        }

        // Output label
        Text {
            text: "output"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textMuted
            renderType: Text.NativeRendering
        }

        // Output device list
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: {
                    let sinks = [];
                    for (let i = 0; i < Pipewire.nodes.values.length; i++) {
                        let node = Pipewire.nodes.values[i];
                        if (node.isSink && !node.isStream && node.audio)
                            sinks.push(node);
                    }
                    return sinks;
                }

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    radius: Theme.itemRadius
                    color: deviceHover.containsMouse && modelData !== Pipewire.defaultAudioSink
                           ? Theme.stateHover : (modelData === Pipewire.defaultAudioSink
                           ? Theme.stateSelected : "transparent")

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 6
                            verticalCenter: parent.verticalCenter
                            right: parent.right
                            rightMargin: 6
                        }
                        text: modelData.description || modelData.name || "Unknown"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: modelData === Pipewire.defaultAudioSink
                               ? Theme.textPrimary : Theme.textMuted
                        renderType: Text.NativeRendering
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: deviceHover
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            Pipewire.preferredDefaultAudioSink = modelData;
                        }
                    }
                }
            }
        }
    }
}

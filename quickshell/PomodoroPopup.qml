pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: popup
    color: "transparent"
    implicitWidth: 200
    implicitHeight: contentCol.implicitHeight + 16

    required property var barWindow
    required property Item anchorItem

    anchor.window: barWindow
    anchor.onAnchoring: {
        let pos = anchorItem.mapToItem(barWindow.contentItem, 0, 0);
        anchor.rect.x = pos.x + anchorItem.width - popup.implicitWidth;
        anchor.rect.y = barWindow.contentItem.height + 8;
    }

    // Delay focus grab so popup surface is fully mapped first
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

    // Timer state
    enum TimerState { Idle, Running, Paused }
    property int timerState: PomodoroPopup.TimerState.Idle
    property int totalSeconds: 0
    property int remainingSeconds: 0

    // Input state: minutes and seconds as editable digits
    property int inputMinutes: 25
    property int inputSeconds: 0

    // Progress: 1.0 = full, 0.0 = done
    readonly property real progress: totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0

    // Expose a short label for the status bar
    readonly property string barLabel: {
        if (timerState === PomodoroPopup.TimerState.Running ||
            timerState === PomodoroPopup.TimerState.Paused) {
            let m = Math.floor(remainingSeconds / 60);
            let s = remainingSeconds % 60;
            return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
        }
        return "tmr";
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: popup.timerState === PomodoroPopup.TimerState.Running
        onTriggered: {
            if (popup.remainingSeconds > 0) {
                popup.remainingSeconds--;
            }
            if (popup.remainingSeconds <= 0) {
                popup.timerState = PomodoroPopup.TimerState.Idle;
                notifyProc.running = true;
            }
        }
    }

    Process {
        id: notifyProc
        command: ["notify-send", "-u", "critical", "Pomodoro", "Time's up!"]
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
        spacing: 12

        // Circular countdown ring
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120

            Canvas {
                id: ringCanvas
                anchors.fill: parent
                antialiasing: true

                property real prog: popup.progress

                onProgChanged: requestPaint()

                Connections {
                    target: Theme
                    function onRevisionChanged() {
                        ringCanvas.requestPaint()
                    }
                }

                onPaint: {
                    let ctx = getContext("2d");
                    ctx.reset();
                    let cx = width / 2;
                    let cy = height / 2;
                    let radius = Math.min(cx, cy) - 8;
                    let lineWidth = 6;

                    // Background track
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
                    ctx.strokeStyle = Theme.surfaceOverlay;
                    ctx.lineWidth = lineWidth;
                    ctx.lineCap = "round";
                    ctx.stroke();

                    // Progress arc (sweeps from top, clockwise)
                    if (prog > 0) {
                        let startAngle = -Math.PI / 2;
                        let endAngle = startAngle + (2 * Math.PI * prog);
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, endAngle);
                        ctx.strokeStyle = popup.timerState === PomodoroPopup.TimerState.Paused
                                          ? Theme.textMuted : Theme.accent;
                        ctx.lineWidth = lineWidth;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }
            }

            // Time display in center of ring
            Text {
                anchors.centerIn: parent
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                renderType: Text.NativeRendering
                text: {
                    if (popup.timerState === PomodoroPopup.TimerState.Idle) {
                        let m = popup.inputMinutes;
                        let s = popup.inputSeconds;
                        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
                    }
                    let m = Math.floor(popup.remainingSeconds / 60);
                    let s = popup.remainingSeconds % 60;
                    return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
                }
            }
        }

        // Time input (only when idle)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: popup.timerState === PomodoroPopup.TimerState.Idle

            // Minutes row
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "min"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textMuted
                    renderType: Text.NativeRendering
                    Layout.preferredWidth: 30
                }

                Item { Layout.fillWidth: true }

                // Minus
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 20
                    radius: Theme.itemRadius
                    color: minMinusHover.containsMouse ? Theme.stateHover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "-"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textPrimary
                        renderType: Text.NativeRendering
                    }
                    MouseArea {
                        id: minMinusHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.inputMinutes = Math.max(0, popup.inputMinutes - 1)
                    }
                }

                Text {
                    text: (popup.inputMinutes < 10 ? "0" : "") + popup.inputMinutes
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    renderType: Text.NativeRendering
                    horizontalAlignment: Text.AlignHCenter
                    Layout.preferredWidth: 24
                }

                // Plus
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 20
                    radius: Theme.itemRadius
                    color: minPlusHover.containsMouse ? Theme.stateHover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textPrimary
                        renderType: Text.NativeRendering
                    }
                    MouseArea {
                        id: minPlusHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.inputMinutes = Math.min(99, popup.inputMinutes + 1)
                    }
                }
            }

            // Seconds row
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "sec"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textMuted
                    renderType: Text.NativeRendering
                    Layout.preferredWidth: 30
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 20
                    radius: Theme.itemRadius
                    color: secMinusHover.containsMouse ? Theme.stateHover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "-"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textPrimary
                        renderType: Text.NativeRendering
                    }
                    MouseArea {
                        id: secMinusHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.inputSeconds = Math.max(0, popup.inputSeconds - 5)
                    }
                }

                Text {
                    text: (popup.inputSeconds < 10 ? "0" : "") + popup.inputSeconds
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    renderType: Text.NativeRendering
                    horizontalAlignment: Text.AlignHCenter
                    Layout.preferredWidth: 24
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 20
                    radius: Theme.itemRadius
                    color: secPlusHover.containsMouse ? Theme.stateHover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textPrimary
                        renderType: Text.NativeRendering
                    }
                    MouseArea {
                        id: secPlusHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.inputSeconds = Math.min(55, popup.inputSeconds + 5)
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.borderSubtle
        }

        // Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Start / Pause / Resume
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                radius: Theme.itemRadius
                color: startHover.containsMouse ? Theme.stateHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (popup.timerState === PomodoroPopup.TimerState.Running) return "pause";
                        if (popup.timerState === PomodoroPopup.TimerState.Paused) return "resume";
                        return "start";
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: startHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (popup.timerState === PomodoroPopup.TimerState.Idle) {
                            let total = popup.inputMinutes * 60 + popup.inputSeconds;
                            if (total <= 0) return;
                            popup.totalSeconds = total;
                            popup.remainingSeconds = total;
                            popup.timerState = PomodoroPopup.TimerState.Running;
                        } else if (popup.timerState === PomodoroPopup.TimerState.Running) {
                            popup.timerState = PomodoroPopup.TimerState.Paused;
                        } else if (popup.timerState === PomodoroPopup.TimerState.Paused) {
                            popup.timerState = PomodoroPopup.TimerState.Running;
                        }
                    }
                }
            }

            // Reset (only when running or paused)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                radius: Theme.itemRadius
                visible: popup.timerState !== PomodoroPopup.TimerState.Idle
                color: resetHover.containsMouse ? Theme.stateHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "reset"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textMuted
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: resetHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        popup.timerState = PomodoroPopup.TimerState.Idle;
                        popup.remainingSeconds = 0;
                        popup.totalSeconds = 0;
                    }
                }
            }
        }

        // Quick presets
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [5, 15, 25, 45]

                delegate: Rectangle {
                    required property int modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    radius: Theme.itemRadius
                    color: presetHover.containsMouse ? Theme.stateHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData + "m"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textMuted
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: presetHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.inputMinutes = modelData;
                            popup.inputSeconds = 0;
                            if (popup.timerState !== PomodoroPopup.TimerState.Idle) {
                                popup.timerState = PomodoroPopup.TimerState.Idle;
                                popup.remainingSeconds = 0;
                                popup.totalSeconds = 0;
                            }
                        }
                    }
                }
            }
        }
    }
}

// StatusBar — combined status bar + scrolling symbol strip
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        left: 8
        right: 8
        top: 4
    }
    implicitHeight: Theme.barHeight + Theme.symbolBarHeight
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Theme.bgColor
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Status bar
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.barHeight
            Layout.leftMargin: Theme.spacingMd
            Layout.rightMargin: Theme.spacingMd
            spacing: Theme.spacingLg

            // Workspaces
            Row {
                spacing: Theme.spacingXs
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {
                        required property var modelData
                        property bool isActive: modelData.id === Hyprland.focusedMonitor?.activeWorkspace?.id
                        property bool isHovered: false

                        width: 28; height: 20
                        radius: Theme.itemRadius
                        color: "transparent"

                        onIsActiveChanged: {
                            if (isActive) {
                                pixelCanvas.startFill()
                            } else {
                                pixelCanvas.stopFill()
                            }
                        }

                        Canvas {
                            id: pixelCanvas
                            anchors.fill: parent
                            visible: pixelFillTimer.running || pixelCanvas.pixelCount > 0
                            z: 0

                            property int pixelSize: 4
                            property int gridW: Math.floor(parent.width / pixelSize)
                            property int gridH: Math.floor(parent.height / pixelSize)
                            property int totalPixels: gridW * gridH
                            property int pixelCount: 0
                            property var positions: []
                            property int batchSize: Math.ceil(totalPixels / 15)

                            function startFill() {
                                let arr = []
                                for (let i = 0; i < totalPixels; i++) arr.push(i)
                                for (let i = arr.length - 1; i > 0; i--) {
                                    let j = Math.floor(Math.random() * (i + 1));
                                    [arr[i], arr[j]] = [arr[j], arr[i]]
                                }
                                positions = arr
                                pixelCount = 0
                                pixelFillTimer.start()
                            }

                            function stopFill() {
                                pixelFillTimer.stop()
                                pixelCount = 0
                                positions = []
                                requestPaint()
                            }

                            onPaint: {
                                let ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.fillStyle = Theme.bgElevatedAlt
                                for (let i = 0; i < pixelCount && i < positions.length; i++) {
                                    let idx = positions[i]
                                    let gx = idx % gridW
                                    let gy = Math.floor(idx / gridW)
                                    ctx.fillRect(gx * pixelSize, gy * pixelSize, pixelSize, pixelSize)
                                }
                            }
                        }

                        Timer {
                            id: pixelFillTimer
                            interval: 40
                            repeat: true
                            onTriggered: {
                                pixelCanvas.pixelCount = Math.min(
                                    pixelCanvas.pixelCount + pixelCanvas.batchSize,
                                    pixelCanvas.totalPixels
                                )
                                pixelCanvas.requestPaint()
                                if (pixelCanvas.pixelCount >= pixelCanvas.totalPixels) stop()
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            z: 1
                            text: modelData.id?.toString() ?? ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: (isActive || isHovered)
                                   ? Theme.textActiveColor : Theme.textInactiveColor
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Hyprland.dispatch("workspace " + parent.modelData.id)
                            onEntered: {
                                parent.isHovered = true
                                if (!parent.isActive) pixelCanvas.startFill()
                            }
                            onExited: {
                                parent.isHovered = false
                                if (!parent.isActive) pixelCanvas.stopFill()
                            }
                        }
                    }
                }
            }

            // Temperature
            Text {
                Layout.alignment: Qt.AlignVCenter
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                color: Theme.textInactiveColor; renderType: Text.NativeRendering
                text: tempProc.temp

                Process {
                    id: tempProc; property string temp: "—"
                    command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf \"%.0f°C\", $1/1000}'"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: tempProc.temp = this.text.trim() }
                }
                Timer { interval: 4000; running: true; repeat: true; onTriggered: tempProc.running = true }
            }

            // Spotify
            Text {
                Layout.alignment: Qt.AlignVCenter
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                color: Theme.textInactiveColor; renderType: Text.NativeRendering
                text: spotifyProc.spotifyText
                visible: spotifyProc.spotifyText !== ""

                Process {
                    id: spotifyProc; property string spotifyText: ""
                    command: ["bash", "-c", "playerctl -p spotify metadata --format '{{artist}} - {{title}}' 2>/dev/null | head -c 40"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: spotifyProc.spotifyText = this.text.trim() }
                }
                Timer { interval: 3000; running: true; repeat: true; onTriggered: spotifyProc.running = true }
            }

            Item { Layout.fillWidth: true }

            // Clock
            Text {
                Layout.alignment: Qt.AlignVCenter
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: Theme.textActiveColor; renderType: Text.NativeRendering
                text: clockProc.timeText

                Process {
                    id: clockProc; property string timeText: ""
                    command: ["date", "+%H:%M   %e %b"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: clockProc.timeText = this.text.trim() }
                }
                Timer { interval: 1000; running: true; repeat: true; onTriggered: clockProc.running = true }
            }

            // Weather
            Text {
                Layout.alignment: Qt.AlignVCenter
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                color: Theme.textInactiveColor; renderType: Text.NativeRendering
                text: weatherProc.weatherText
                visible: weatherProc.weatherText !== ""

                Process {
                    id: weatherProc; property string weatherText: ""
                    command: ["bash", "-c", "curl -sf 'https://wttr.in/?format=%C+%t' 2>/dev/null | sed 's/+//g'"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: weatherProc.weatherText = this.text.trim() }
                }
                Timer { interval: 3600000; running: true; repeat: true; onTriggered: weatherProc.running = true }
            }

            Item { Layout.fillWidth: true }

            // Memory
            Text {
                Layout.alignment: Qt.AlignVCenter
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                color: Theme.textInactiveColor; renderType: Text.NativeRendering
                text: memProc.memText

                Process {
                    id: memProc; property string memText: ""
                    command: ["bash", "-c", "free -h | awk '/^Mem:/{print $3\"/\"$2}'"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: memProc.memText = this.text.trim() }
                }
                Timer { interval: 5000; running: true; repeat: true; onTriggered: memProc.running = true }
            }

            // Battery
            Text {
                Layout.alignment: Qt.AlignVCenter
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                color: Theme.textInactiveColor; renderType: Text.NativeRendering
                text: battProc.battText

                Process {
                    id: battProc; property string battText: "—"
                    command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 | xargs -I{} echo '{}%'"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: { let t = this.text.trim(); if (t) battProc.battText = t } }
                }
                Timer { interval: 10000; running: true; repeat: true; onTriggered: battProc.running = true }
            }

            // Volume
            Text {
                Layout.alignment: Qt.AlignVCenter
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                color: Theme.textInactiveColor; renderType: Text.NativeRendering
                text: volProc.volText

                Process {
                    id: volProc; property string volText: "—"
                    command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf \"%.0f%%\", $2*100}'"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: { let t = this.text.trim(); if (t) volProc.volText = t } }
                }
                Timer { interval: 2000; running: true; repeat: true; onTriggered: volProc.running = true }
            }

            // Power
            Text {
                Layout.alignment: Qt.AlignVCenter
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                color: Theme.textActiveColor; renderType: Text.NativeRendering
                text: "pwr"

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: powerProc.running = true
                }
                Process { id: powerProc; command: ["wlogout"] }
            }
        }

        // Scrolling symbol strip
        Item {
            id: symbolStrip
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.symbolBarHeight
            clip: true

            readonly property var symbols: [
                "☉", "☽", "♄", "♃", "☿", "♀", "♂", "⚶", "☊", "☋"
            ]

            property string fullString: ""

            Component.onCompleted: {
                let arr = [...symbols]
                for (let i = arr.length - 1; i > 0; i--) {
                    let j = Math.floor(Math.random() * (i + 1));
                    [arr[i], arr[j]] = [arr[j], arr[i]]
                }
                let segment = ""
                for (let r = 0; r < 30; r++) {
                    let copy = [...arr]
                    for (let i = copy.length - 1; i > 0; i--) {
                        let j = Math.floor(Math.random() * (i + 1));
                        [copy[i], copy[j]] = [copy[j], copy[i]]
                    }
                    segment += copy.join("      ") + "      "
                }
                fullString = segment + segment
                startTimer.start()
            }

            Timer {
                id: startTimer
                interval: 100
                onTriggered: {
                    if (scrollText.implicitWidth > 0) {
                        let seg = scrollText.implicitWidth / 2
                        scrollAnim.from = 0
                        scrollAnim.to = -seg
                        scrollAnim.duration = (seg / 50) * 1000
                        scrollAnim.restart()
                    }
                }
            }

            Item {
                id: scrollContainer
                width: scrollText.implicitWidth
                height: parent.height
                x: 0

                Text {
                    id: scrollText
                    text: symbolStrip.fullString
                    color: Theme.symbolColor
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                NumberAnimation on x {
                    id: scrollAnim
                    running: false
                    from: 0
                    to: 0
                    duration: 1000
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: Theme.borderColor
        border.width: 1
        z: 2
    }
}

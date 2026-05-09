pragma Singleton
import QtQuick

QtObject {
    readonly property string id: "dark"

    readonly property color background: "#0a0a0a"
    readonly property color card: "#171717"
    readonly property color secondary: "#262626"
    readonly property color mutedForeground: "#a1a1a1"
    readonly property color foreground: "#fafafa"
    readonly property color borderColor: Qt.rgba(1, 1, 1, 0.1)

    readonly property color bgColor: card
    readonly property color bgElevatedAlt: secondary
    readonly property color textActiveColor: foreground
    readonly property color textInactiveColor: mutedForeground
    readonly property color symbolColor: "#b0b0b0"
    readonly property color symbolColorDim: "#666666"
    readonly property color critical: "#c45050"
    readonly property color good: "#6b9b6b"

    readonly property int spacingXs: 2
    readonly property int spacingSm: 4
    readonly property int spacingMd: 8
    readonly property int spacingLg: 12

    readonly property int itemRadius: 2
    readonly property string fontFamily: "PP Fraktion Mono"
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeNormal: 12

    readonly property int animationDuration: 200

    readonly property int barHeight: 32
    readonly property int symbolBarHeight: 24
}

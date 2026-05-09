pragma Singleton
import QtQuick

QtObject {
    readonly property string id: "light"

    readonly property color background: "#f4f1ea"
    readonly property color card: "#ece7dd"
    readonly property color secondary: "#ddd6c9"
    readonly property color mutedForeground: "#736b5f"
    readonly property color foreground: "#1f1c16"
    readonly property color borderColor: Qt.rgba(0, 0, 0, 0.14)

    readonly property color bgColor: card
    readonly property color bgElevatedAlt: secondary
    readonly property color textActiveColor: foreground
    readonly property color textInactiveColor: mutedForeground
    readonly property color symbolColor: "#5e5548"
    readonly property color symbolColorDim: "#9a907f"
    readonly property color critical: "#b0463c"
    readonly property color good: "#4f7a4f"

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

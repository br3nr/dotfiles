pragma Singleton
import QtQuick
import "themes" as ThemeSet

QtObject {
    property string variant: "dark"
    readonly property QtObject _active: variant === "light" ? ThemeSet.LightTheme : ThemeSet.DarkTheme

    readonly property color background: _active.background
    readonly property color card: _active.card
    readonly property color secondary: _active.secondary
    readonly property color mutedForeground: _active.mutedForeground
    readonly property color foreground: _active.foreground
    readonly property color borderColor: _active.borderColor

    readonly property color bgColor: _active.bgColor
    readonly property color bgElevatedAlt: _active.bgElevatedAlt
    readonly property color textActiveColor: _active.textActiveColor
    readonly property color textInactiveColor: _active.textInactiveColor
    readonly property color symbolColor: _active.symbolColor
    readonly property color symbolColorDim: _active.symbolColorDim
    readonly property color critical: _active.critical
    readonly property color good: _active.good

    readonly property int spacingXs: _active.spacingXs
    readonly property int spacingSm: _active.spacingSm
    readonly property int spacingMd: _active.spacingMd
    readonly property int spacingLg: _active.spacingLg

    readonly property int itemRadius: _active.itemRadius
    readonly property string fontFamily: _active.fontFamily
    readonly property int fontSizeSmall: _active.fontSizeSmall
    readonly property int fontSizeNormal: _active.fontSizeNormal

    readonly property int animationDuration: _active.animationDuration

    readonly property int barHeight: _active.barHeight
    readonly property int symbolBarHeight: _active.symbolBarHeight
}

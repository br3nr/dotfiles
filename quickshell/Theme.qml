pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property var fallbackTheme: ({
        id: "fallback",
        name: "Fallback",
        appearance: "dark",
        quickshell: {
            background: "#0a0a0a",
            card: "#171717",
            secondary: "#262626",
            mutedForeground: "#a1a1a1",
            foreground: "#fafafa",
            borderColor: "#1affffff",
            symbolColor: "#b0b0b0",
            symbolColorDim: "#666666",
            critical: "#c45050",
            good: "#6b9b6b",
            fontFamily: "PP Fraktion Mono",
            fontSizeSmall: 10,
            fontSizeNormal: 12,
            spacingXs: 2,
            spacingSm: 4,
            spacingMd: 8,
            spacingLg: 12,
            itemRadius: 2,
            animationDuration: 200,
            barHeight: 32,
            symbolBarHeight: 24
        }
    })

    property var activeTheme: fallbackTheme
    property int revision: 0
    readonly property var palette: activeTheme.quickshell
    readonly property string themeId: activeTheme.id
    readonly property string themeName: activeTheme.name
    readonly property string appearance: activeTheme.appearance

    function loadTheme(): void {
        try {
            const parsed = JSON.parse(themeFile.text())
            if (!parsed.id || !parsed.quickshell)
                throw new Error("theme manifest is missing required fields")
            activeTheme = parsed
            revision++
        } catch (error) {
            console.warn("Unable to load active theme:", error)
        }
    }

    property FileView themeFile: FileView {
        path: Quickshell.env("HOME") + "/.config/theme/generated/active.json"
        preload: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.loadTheme()
    }

    readonly property color background: palette.background
    readonly property color card: palette.card
    readonly property color secondary: palette.secondary
    readonly property color mutedForeground: palette.mutedForeground
    readonly property color foreground: palette.foreground
    readonly property color borderColor: palette.borderColor

    readonly property color bgColor: card
    readonly property color bgElevatedAlt: secondary
    readonly property color textActiveColor: foreground
    readonly property color textInactiveColor: mutedForeground
    readonly property color symbolColor: palette.symbolColor
    readonly property color symbolColorDim: palette.symbolColorDim
    readonly property color critical: palette.critical
    readonly property color good: palette.good

    readonly property int spacingXs: palette.spacingXs
    readonly property int spacingSm: palette.spacingSm
    readonly property int spacingMd: palette.spacingMd
    readonly property int spacingLg: palette.spacingLg
    readonly property int itemRadius: palette.itemRadius
    readonly property string fontFamily: palette.fontFamily
    readonly property int fontSizeSmall: palette.fontSizeSmall
    readonly property int fontSizeNormal: palette.fontSizeNormal
    readonly property int animationDuration: palette.animationDuration
    readonly property int barHeight: palette.barHeight
    readonly property int symbolBarHeight: palette.symbolBarHeight
}

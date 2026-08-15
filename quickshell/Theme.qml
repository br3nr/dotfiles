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
        identity: {
            ascii: "$HOME/.config/ascii/arachne.txt"
        },
        quickshell: {
            surfaceBase: "#0a0a0a",
            surfaceRaised: "#171717",
            surfaceOverlay: "#202020",
            textPrimary: "#fafafa",
            textSecondary: "#c8c8c8",
            textMuted: "#8c8c8c",
            textDisabled: "#555555",
            accent: "#d8d8d8",
            onAccent: "#0a0a0a",
            stateHover: "#262626",
            statePressed: "#303030",
            stateSelected: "#383838",
            borderSubtle: "#1affffff",
            borderStrong: "#66ffffff",
            success: "#6b9b6b",
            warning: "#c49b54",
            error: "#c45050",
            info: "#668eaa",
            decorative: "#b0b0b0",
            decorativeMuted: "#666666",
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
    // The active manifest and fallback implement the same semantic palette contract.
    readonly property var palette: activeTheme.quickshell
    readonly property string themeId: activeTheme.id
    readonly property string themeName: activeTheme.name
    readonly property string appearance: activeTheme.appearance
    readonly property string asciiIdentity: activeTheme.identity
                                            ? activeTheme.identity.ascii
                                            : fallbackTheme.identity.ascii

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

    readonly property color surfaceBase: palette.surfaceBase
    readonly property color surfaceRaised: palette.surfaceRaised
    readonly property color surfaceOverlay: palette.surfaceOverlay
    readonly property color textPrimary: palette.textPrimary
    readonly property color textSecondary: palette.textSecondary
    readonly property color textMuted: palette.textMuted
    readonly property color textDisabled: palette.textDisabled
    readonly property color accent: palette.accent
    readonly property color onAccent: palette.onAccent
    readonly property color stateHover: palette.stateHover
    readonly property color statePressed: palette.statePressed
    readonly property color stateSelected: palette.stateSelected
    readonly property color borderSubtle: palette.borderSubtle
    readonly property color borderStrong: palette.borderStrong
    readonly property color success: palette.success
    readonly property color warning: palette.warning
    readonly property color error: palette.error
    readonly property color info: palette.info
    readonly property color decorative: palette.decorative
    readonly property color decorativeMuted: palette.decorativeMuted

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

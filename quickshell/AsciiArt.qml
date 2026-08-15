pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string source: ""
    property color color: Theme.decorative
    property int nativeFontSize: 12
    property real maximumScale: 1.0
    property string content: ""

    readonly property string expandedSource: source.replace(/^\$HOME/, Quickshell.env("HOME"))
    readonly property real fitScale: {
        if (artwork.implicitWidth <= 0 || artwork.implicitHeight <= 0)
            return 1.0;
        return Math.min(
            maximumScale,
            width / artwork.implicitWidth,
            height / artwork.implicitHeight
        );
    }

    function normalize(value): string {
        return value
            .replace(/^(?:[ \t]*\r?\n)+/, "")
            .replace(/(?:\r?\n[ \t]*)+$/, "");
    }

    FileView {
        path: root.expandedSource
        preload: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.content = root.normalize(text())
    }

    Text {
        id: artwork
        anchors.centerIn: parent
        text: root.content
        textFormat: Text.PlainText
        wrapMode: Text.NoWrap
        color: root.color
        font.family: Theme.fontFamily
        font.pixelSize: root.nativeFontSize
        renderType: Text.QtRendering
        scale: root.fitScale
        transformOrigin: Item.Center
        layer.enabled: root.fitScale !== 1.0
        layer.smooth: true
    }
}

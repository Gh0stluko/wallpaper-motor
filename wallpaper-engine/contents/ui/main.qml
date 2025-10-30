import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0

// Plasma wallpaper QML entry: root must be a WallpaperItem in Plasma 6
WallpaperItem {
    id: root
    anchors.fill: parent

    // Access KConfig via WallpaperItem.configuration (KConfigPropertyMap)
    // Provide fallbacks for safety if keys are missing
    
    // Parse playlist from comma-separated string
    property var playlist: {
        if (!configuration || !configuration.playlist) return []
        var str = configuration.playlist.toString().trim()
        if (!str || str.length === 0) return []
        // Split and clean each URL
        return str.split(',').map(function(s) { 
            return s.trim().replace(/\\+$/, '') // Remove trailing backslashes
        }).filter(function(s) { 
            return s.length > 0 
        })
    }
    
    property int intervalSeconds: (configuration && configuration.intervalSeconds !== undefined) ? configuration.intervalSeconds : 30
    property int crossfadeMs: (configuration && configuration.crossfadeMs !== undefined) ? configuration.crossfadeMs : 800
    property bool shuffle: (configuration && configuration.shuffle !== undefined) ? configuration.shuffle : false

    // Internal state
    property int currentIndex: -1
    property string currentSource: ""
    property string nextSource: ""

    // Double-buffered images for crossfade with smooth blending
    Image {
        id: imgA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: root.currentSource
        visible: true
        opacity: 1.0
        smooth: true
        cache: true
        asynchronous: true
        mipmap: true
    }
    Image {
        id: imgB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: root.nextSource
        visible: true
        opacity: 0.0
        smooth: true
        cache: true
        asynchronous: true
        mipmap: true
    }

    // Crossfade animation with smooth blending - uses slower middle part for beautiful overlap
    SequentialAnimation {
        id: crossfadeAnim
        running: false
        ParallelAnimation {
            NumberAnimation { 
                target: imgA
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: root.crossfadeMs
                easing.type: Easing.InOutQuart
            }
            NumberAnimation { 
                target: imgB
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: root.crossfadeMs
                easing.type: Easing.InOutQuart
            }
        }
        onStopped: {
            // Swap buffers
            root.currentSource = imgB.source
            imgA.opacity = 1.0
            imgB.opacity = 0.0
            imgA.source = root.currentSource
            imgB.source = ""
        }
    }

    // Timer for slideshow
    Timer {
        id: slideTimer
        running: playlist.length > 1 && root.intervalSeconds > 0
        repeat: true
        interval: Math.max(1, root.intervalSeconds) * 1000
        onTriggered: advance()
    }

    function nextIndex() {
        if (playlist.length === 0) return -1
        if (shuffle) {
            return Math.floor(Math.random() * playlist.length)
        }
        return (currentIndex + 1) % playlist.length
    }

    function advance() {
        if (playlist.length === 0) return
        var idx = nextIndex()
        if (idx < 0) return
        currentIndex = idx
        var src = playlist[idx]
        if (!src || src === currentSource) {
            // Avoid crossfading to same image
            return
        }
        nextSource = src
        // Start crossfade
        crossfadeAnim.stop()
        imgB.source = nextSource
        crossfadeAnim.start()
    }

    Component.onCompleted: {
        if (playlist.length > 0) {
            currentIndex = 0
            currentSource = playlist[0]
            imgA.source = currentSource
        }
        if (playlist.length > 1) {
            slideTimer.start()
        }
    }
}

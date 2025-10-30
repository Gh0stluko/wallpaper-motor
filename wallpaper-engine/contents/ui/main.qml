import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia
import org.kde.plasma.plasmoid 2.0

// Plasma wallpaper QML entry: root must be a WallpaperItem in Plasma 6
WallpaperItem {
    id: root
    anchors.fill: parent

    // Access KConfig via WallpaperItem.configuration (KConfigPropertyMap)
    // Provide fallbacks for safety if keys are missing
    
    property string mode: (configuration && configuration.mode) ? configuration.mode : "photo"
    property string steamDirectory: (configuration && configuration.steamDirectory) ? configuration.steamDirectory : ""
    property string weWallpaper: (configuration && configuration.weWallpaper) ? configuration.weWallpaper : ""
    
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

    // Determine active mode: use WE if mode is set to "wallpaper-engine" AND wallpaper is selected
    property bool useWallpaperEngine: mode === "wallpaper-engine" && weWallpaper.length > 0
    property string weWallpaperPath: {
        if (!useWallpaperEngine || !steamDirectory || steamDirectory.length === 0) return ""
        var steamDir = steamDirectory.toString().replace('file://', '')
        return steamDir + '/steamapps/workshop/content/431960/' + weWallpaper
    }

    // Watch for configuration changes
    onModeChanged: {
        console.log("Mode changed to: " + mode)
        if (mode === "photo") {
            // Switch to photo mode
            weLoader.active = false
            if (playlist.length > 0) {
                currentIndex = 0
                currentSource = playlist[0]
                imgA.source = currentSource
            }
        } else if (mode === "wallpaper-engine") {
            // Switch to WE mode
            if (weWallpaper.length > 0) {
                Qt.callLater(function() {
                    weLoader.active = false
                    weLoader.active = true
                })
            }
        }
    }
    
    onWeWallpaperChanged: {
        console.log("Wallpaper changed to: " + weWallpaper)
        if (mode === "wallpaper-engine" && weWallpaper.length > 0) {
            // Force reload by toggling loader
            Qt.callLater(function() {
                weLoader.active = false
                weLoader.active = true
            })
        }
    }
    
    onUseWallpaperEngineChanged: {
        console.log("useWallpaperEngine changed to: " + useWallpaperEngine)
    }
    
    onPlaylistChanged: {
        if (mode === "photo" && playlist.length > 0) {
            currentIndex = 0
            currentSource = playlist[0]
            imgA.source = currentSource
        }
    }

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
        visible: !root.useWallpaperEngine
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
        visible: !root.useWallpaperEngine
        opacity: 0.0
        smooth: true
        cache: true
        asynchronous: true
        mipmap: true
    }

    // Wallpaper Engine video/image display
    Loader {
        id: weLoader
        anchors.fill: parent
        active: root.useWallpaperEngine
        sourceComponent: weDisplayComponent
    }

    Component {
        id: weDisplayComponent
        
        Item {
            anchors.fill: parent
            
            property string projectFile: weWallpaperPath + '/project.json'
            property var projectData: null
            property string wallpaperFile: ""
            property string wallpaperType: ""
            
            Component.onCompleted: {
                console.log("Loading WE wallpaper from: " + weWallpaperPath)
                loadProjectData()
            }
            
            function loadProjectData() {
                var xhr = new XMLHttpRequest()
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200 || xhr.status === 0) {
                            try {
                                projectData = JSON.parse(xhr.responseText)
                                wallpaperFile = 'file://' + weWallpaperPath + '/' + projectData.file
                                wallpaperType = projectData.type || 'unknown'
                                console.log("WE Wallpaper loaded - Type: " + wallpaperType + ", File: " + wallpaperFile)
                            } catch (e) {
                                console.log("Error parsing project.json: " + e)
                            }
                        } else {
                            console.log("Failed to load project.json, status: " + xhr.status)
                        }
                    }
                }
                xhr.open("GET", "file://" + projectFile)
                xhr.send()
            }
            
            // Video player for video wallpapers
            Video {
                id: videoPlayer
                anchors.fill: parent
                visible: wallpaperType === "video" || wallpaperType === "Video"
                source: visible ? wallpaperFile : ""
                autoPlay: true
                loops: MediaPlayer.Infinite
                fillMode: VideoOutput.PreserveAspectCrop
                muted: true
                
                Component.onCompleted: {
                    console.log("Video player created for: " + source)
                }
                
                onPlaybackStateChanged: {
                    console.log("Video playback state: " + playbackState)
                }
                
                onErrorStringChanged: {
                    if (errorString.length > 0) {
                        console.log("Video error: " + errorString)
                    }
                }
            }
            
            // Image display for image/scene wallpapers  
            Image {
                id: staticImage
                anchors.fill: parent
                visible: wallpaperType === "image" || wallpaperType === "scene" || wallpaperType === "Scene"
                source: visible ? wallpaperFile : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                
                Component.onCompleted: {
                    console.log("Image created for: " + source)
                }
            }
        }
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
        running: !root.useWallpaperEngine && playlist.length > 1 && root.intervalSeconds > 0
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
        console.log("Wallpaper plugin initialized - Mode: " + mode)
        if (mode === "photo" && playlist.length > 0) {
            currentIndex = 0
            currentSource = playlist[0]
            imgA.source = currentSource
            if (playlist.length > 1) {
                slideTimer.start()
            }
        }
    }
}

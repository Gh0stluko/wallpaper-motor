import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import Qt.labs.platform 1.1 as Platform
import Qt.labs.folderlistmodel 2.15
import org.kde.kirigami 2.20 as Kirigami

// Configuration UI for the wallpaper plugin
ColumnLayout {
    id: root

    // KCM bridge
    property QtObject configDialog
    property QtObject wallpaperConfiguration

    // KConfig bindings (Plasma reads cfg_* values)
    property string cfg_playlist
    property alias cfg_intervalSeconds: intervalField.value
    property alias cfg_crossfadeMs: crossfadeField.value
    property alias cfg_shuffle: shuffleCheck.checked
    property string cfg_steamDirectory
    property string cfg_weWallpaper
    property string cfg_mode: "photo" // "photo" or "wallpaper-engine"

    // Tabs
    TabBar {
        id: tabs
        Layout.fillWidth: true
        TabButton { text: qsTr("Photo") }
        TabButton { text: qsTr("Wallpaper Engine") }
        TabButton { text: qsTr("About") }
    }

    // Model storing selected files (shared across pages if needed)
    ListModel { id: playlistModel }
    ListModel { id: weWallpapersModel }

    // Timer to process wallpaper scanning via Python script
    Timer {
        id: scanTimer
        interval: 100
        repeat: false
        onTriggered: executePythonScan()
    }

    function executePythonScan() {
        if (!cfg_steamDirectory || cfg_steamDirectory.length === 0) return
        
        var steamDir = cfg_steamDirectory.toString().replace('file://', '')
        var scriptPath = Qt.resolvedUrl("../code/scan_wallpapers.py").toString().replace('file://', '')
        
        // Execute Python script synchronously
        var process = pythonProcess.createObject(root, {
            steamDir: steamDir,
            scriptPath: scriptPath
        })
    }

    Component {
        id: pythonProcess
        Item {
            id: processItem
            property string steamDir
            property string scriptPath
            
            Component.onCompleted: {
                // Use a simple approach: create a temp component that runs python
                var xhr = new XMLHttpRequest()
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            try {
                                var wallpapers = JSON.parse(xhr.responseText)
                                weWallpapersModel.clear()
                                
                                for (var i = 0; i < wallpapers.length; i++) {
                                    var wp = wallpapers[i]
                                    weWallpapersModel.append({
                                        id: wp.id,
                                        title: wp.title,
                                        preview: 'file://' + wp.preview,
                                        file: 'file://' + wp.file,
                                        type: wp.type,
                                        description: wp.description
                                    })
                                }
                                console.log("Loaded " + wallpapers.length + " wallpapers via Python")
                            } catch (e) {
                                console.log("Error parsing Python output: " + e)
                                // Fallback to FolderListModel approach
                                scanViaFolderList()
                            }
                        } else {
                            console.log("Python script failed, using fallback")
                            scanViaFolderList()
                        }
                        processItem.destroy()
                    }
                }
                
                // Try to execute via a data URL or inline script
                var cmd = 'python3 "' + scriptPath + '" "' + steamDir + '"'
                console.log("Attempting to run: " + cmd)
                
                // This won't work directly, so use fallback
                scanViaFolderList()
                processItem.destroy()
            }
        }
    }

    function scanViaFolderList() {
        if (!cfg_steamDirectory || cfg_steamDirectory.length === 0) return
        var steamDir = cfg_steamDirectory.toString().replace('file://', '')
        var workshopPath = steamDir + '/steamapps/workshop/content/431960'
        console.log("Scanning via FolderListModel: " + workshopPath)
        workshopFolders.folder = "file://" + workshopPath
    }

    FolderListModel {
        id: workshopFolders
        showDirs: true
        showFiles: false
        
        onStatusChanged: {
            console.log("FolderListModel status: " + status)
            if (status === FolderListModel.Ready) {
                console.log("Found " + count + " folders")
                weWallpapersModel.clear()
                for (var i = 0; i < count; ++i) {
                    var folderName = get(i, "fileName")
                    if (folderName === "." || folderName === "..") continue
                    
                    var folderPath = folder.toString().replace('file://', '') + '/' + folderName
                    loadWallpaperData(folderName, folderPath)
                }
            }
        }
    }

    function loadWallpaperData(folderId, folderPath) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        var previewPath = folderPath + '/' + (data.preview || 'preview.gif')
                        var filePath = folderPath + '/' + data.file
                        
                        console.log("Loaded wallpaper: " + data.title + " (type: " + data.type + ")")
                        
                        weWallpapersModel.append({
                            id: folderId,
                            title: data.title || folderId,
                            preview: 'file://' + previewPath,
                            file: 'file://' + filePath,
                            type: data.type || 'unknown',
                            description: data.description || ''
                        })
                    } catch (e) {
                        console.log("Error parsing project.json for " + folderId + ": " + e)
                    }
                } else if (xhr.status !== 0) {
                    console.log("Failed to load project.json for " + folderId + " (status: " + xhr.status + ")")
                }
            }
        }
        xhr.open("GET", "file://" + folderPath + '/project.json')
        xhr.send()
    }

    // Helpers
    function playlistFromString(str) {
        if (!str || str.length === 0) return []
        return str.split(',').filter(function(s) { return s.trim().length > 0 })
    }

    function playlistToString(arr) { return arr.join(',') }

    function scanWallpaperEngine() {
        weWallpapersModel.clear()
        if (!cfg_steamDirectory || cfg_steamDirectory.length === 0) {
            console.log("No Steam directory configured")
            return
        }
        
        console.log("Starting wallpaper scan...")
        // Use the FolderListModel approach directly (works everywhere)
        scanViaFolderList()
    }

    function updatePlaylist() {
        var out = []
        for (var i = 0; i < playlistModel.count; ++i) {
            out.push(playlistModel.get(i).url)
        }
        cfg_playlist = playlistToString(out)
    }

    Component.onCompleted: {
        // Load once from saved config
        var arr = playlistFromString(cfg_playlist)
        for (var i = 0; i < arr.length; ++i) playlistModel.append({ url: arr[i] })
        
        // Load Wallpaper Engine wallpapers if Steam directory is set
        if (cfg_steamDirectory && cfg_steamDirectory.length > 0) {
            scanWallpaperEngine()
        }
    }

    // File picker for Photo tab
    FileDialog {
        id: fileDialog
        title: qsTr("Add images to playlist")
        fileMode: FileDialog.OpenFiles
        nameFilters: [ qsTr("Images (*.png *.jpg *.jpeg *.gif *.bmp *.webp *.avif)") ]
        onAccepted: {
            for (var i = 0; i < fileDialog.selectedFiles.length; ++i) {
                var u = fileDialog.selectedFiles[i]
                var s = typeof u === 'string' ? u : u.toString()
                playlistModel.append({ url: s })
            }
            updatePlaylist()
        }
    }

    // Pages
    StackLayout {
        id: pages
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: tabs.currentIndex

        // Photo page (existing functionality)
        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                
                Kirigami.Heading { 
                    text: qsTr("Photo Playlist")
                    level: 3
                    Layout.fillWidth: true 
                }
                
                Button {
                    text: cfg_mode === "photo" ? qsTr("✓ Active") : qsTr("Use this mode")
                    highlighted: cfg_mode === "photo"
                    onClicked: {
                        cfg_mode = "photo"
                        cfg_weWallpaper = "" // Clear WE selection
                    }
                }
            }

            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                Button { text: qsTr("Add"); onClicked: fileDialog.open() }
                Button {
                    text: qsTr("Remove selected"); enabled: view.currentIndex >= 0
                    onClicked: {
                        if (view.currentIndex >= 0) {
                            playlistModel.remove(view.currentIndex)
                            updatePlaylist()
                        }
                    }
                }
                Button {
                    text: qsTr("Move up"); enabled: view.currentIndex > 0
                    onClicked: {
                        var i = view.currentIndex
                        playlistModel.move(i, i-1, 1)
                        view.currentIndex = i-1
                        updatePlaylist()
                    }
                }
                Button {
                    text: qsTr("Move down"); enabled: view.currentIndex >= 0 && view.currentIndex < playlistModel.count-1
                    onClicked: {
                        var i = view.currentIndex
                        playlistModel.move(i, i+1, 1)
                        view.currentIndex = i+1
                        updatePlaylist()
                    }
                }
                Item { Layout.fillWidth: true }
            }

            GridView {
                id: view
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: 140
                cellHeight: 100
                model: playlistModel
                clip: true
                
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
                
                delegate: Frame {
                    width: 130; height: 90
                    property bool selected: GridView.isCurrentItem
                    background: Rectangle { color: selected ? Kirigami.Theme.highlightColor : 'transparent'; radius: 6; border.width: 1; border.color: Kirigami.Theme.textColor }
                    Image { anchors.fill: parent; anchors.margins: 4; fillMode: Image.PreserveAspectCrop; source: model.url }
                    MouseArea { anchors.fill: parent; onClicked: view.currentIndex = index }
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            Kirigami.Heading { text: qsTr("Playback"); level: 3; Layout.fillWidth: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Label { text: qsTr("Interval (s):") }
                SpinBox {
                    id: intervalField
                    from: 1; to: 36000; value: 30
                }

                Item { Layout.fillWidth: true }

                Label { text: qsTr("Crossfade (ms):") }
                SpinBox {
                    id: crossfadeField
                    from: 0; to: 10000; value: 5000
                    stepSize: 100
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                CheckBox {
                    id: shuffleCheck
                    text: qsTr("Shuffle")
                    checked: false
                }
                Item { Layout.fillWidth: true }
            }
        }

        // Wallpaper Engine page
        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                
                Kirigami.Heading { 
                    text: qsTr("Wallpaper Engine")
                    level: 3
                    Layout.fillWidth: true 
                }
                
                Button {
                    text: cfg_mode === "wallpaper-engine" ? qsTr("✓ Active") : qsTr("Use this mode")
                    highlighted: cfg_mode === "wallpaper-engine"
                    onClicked: cfg_mode = "wallpaper-engine"
                }
            }

            Label { 
                text: qsTr("Select your Steam directory to import Wallpaper Engine wallpapers")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextField {
                    id: steamDirField
                    Layout.fillWidth: true
                    placeholderText: qsTr("/home/user/.local/share/Steam")
                    text: cfg_steamDirectory ? cfg_steamDirectory.toString().replace('file://', '') : ''
                    onTextChanged: {
                        cfg_steamDirectory = text
                    }
                }

                Button {
                    text: qsTr("Browse...")
                    onClicked: steamDirDialog.open()
                }

                Button {
                    text: qsTr("Scan")
                    enabled: steamDirField.text.length > 0
                    onClicked: scanWallpaperEngine()
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            Kirigami.Heading { 
                text: qsTr("Available Wallpapers (%1)").arg(weWallpapersModel.count)
                level: 4
                Layout.fillWidth: true 
            }

            GridView {
                id: weView
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: 200
                cellHeight: 180
                model: weWallpapersModel
                clip: true
                
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
                
                delegate: Item {
                        width: 190
                        height: 170

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 4

                            Frame {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 120
                                
                                property bool selected: cfg_weWallpaper === model.id
                                
                                background: Rectangle {
                                    color: parent.selected ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                                    radius: 6
                                    border.width: 2
                                    border.color: parent.selected ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                }

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    fillMode: Image.PreserveAspectCrop
                                    source: model.preview
                                    smooth: true
                                    asynchronous: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        cfg_weWallpaper = model.id
                                        cfg_mode = "wallpaper-engine" // Auto-switch to WE mode
                                    }
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: model.title
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                font.bold: cfg_weWallpaper === model.id
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Type: %1").arg(model.type)
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                opacity: 0.7
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        visible: weWallpapersModel.count === 0 && steamDirField.text.length > 0
                        text: qsTr("No wallpapers found. Click 'Scan' to search.")
                        opacity: 0.6
                    }

                    Label {
                        anchors.centerIn: parent
                        visible: steamDirField.text.length === 0
                        text: qsTr("Enter your Steam directory and click 'Scan' to begin")
                        opacity: 0.6
                    }
                }
            }

        // About page (basic info)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                Kirigami.Heading { text: qsTr("About"); level: 3 }
                Label { text: qsTr("Wallpaper Engine (KDE Plasma 6) plugin") }
                Label { text: qsTr("Author: gluko") }
                Label { text: qsTr("A playlist-based wallpaper with smooth crossfade transitions and previews.") ; wrapMode: Text.WordWrap }
                Item { Layout.fillHeight: true }
            }
        }
    }

    // File dialogs outside StackLayout
    Platform.FolderDialog {
        id: steamDirDialog
        title: qsTr("Select Steam Directory")
        folder: steamDirField.text.length > 0 ? ("file://" + steamDirField.text) : Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation)
        onAccepted: {
            var path = folder.toString().replace('file://', '')
            steamDirField.text = path
            cfg_steamDirectory = path
            scanWallpaperEngine()
        }
    }
}

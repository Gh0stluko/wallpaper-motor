import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import org.kde.kirigami 2.20 as Kirigami
import Qt.labs.folderlistmodel

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
    property string cfg_steamDir

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

    // Helpers
    function playlistFromString(str) {
        if (!str || str.length === 0) return []
        return str.split(',').filter(function(s) { return s.trim().length > 0 })
    }

    function playlistToString(arr) { return arr.join(',') }

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

            Kirigami.Heading { text: qsTr("Playlist"); level: 3; Layout.fillWidth: true }

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
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // Helpers for path/url
            function toStringUrl(u) { return (u && u.toString) ? u.toString() : (typeof u === 'string' ? u : "") }
            function toFileUrl(p) {
                if (!p) return ""
                if (typeof p !== 'string') p = toStringUrl(p)
                if (p.startsWith("file://")) return p
                // ensure exactly three slashes after scheme
                if (p.startsWith('/')) return "file://" + p
                return "file:///" + p
            }
            function joinUrl(base, suffix) {
                var b = toStringUrl(base)
                if (!b) return ""
                if (b.endsWith('/')) b = b.substring(0, b.length-1)
                return b + '/' + suffix
            }
            // Resolve workshop root
            property string steamRootUrl: toFileUrl(root.cfg_steamDir)
            property string workshopUrl: joinUrl(steamRootUrl, "steamapps/workshop/content/431960")

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing

                Kirigami.Heading { text: qsTr("Wallpaper Engine"); level: 3 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Label { text: qsTr("Steam dir:") }
                    TextField {
                        id: steamDirField
                        Layout.fillWidth: true
                        text: root.cfg_steamDir
                        placeholderText: qsTr("/home/user/.local/share/Steam/")
                        onEditingFinished: root.cfg_steamDir = text
                    }
                    Button { text: qsTr("Browse…"); onClicked: steamFolderDialog.open() }
                    Button { text: qsTr("Refresh"); onClicked: weDirs.refresh() }
                }

                Label {
                    text: workshopUrl ? qsTr("Workshop: %1 — items: %2").arg(workshopUrl).arg(weDirs.count) : qsTr("Set Steam directory to scan Workshop content (app 431960).")
                    wrapMode: Text.WordWrap
                    opacity: 0.8
                }

                // Directory chooser
                FolderDialog {
                    id: steamFolderDialog
                    title: qsTr("Select your Steam directory")
                    onAccepted: {
                        // folder may be url (QUrl) or string
                        var u = typeof selectedFolder === 'string' ? selectedFolder : selectedFolder.toString()
                        // Normalize to local path (strip file://) for storage
                        if (u.startsWith('file://')) u = u.substring(7)
                        root.cfg_steamDir = u
                        steamDirField.text = u
                        // Keep binding on weDirs.folder; just refresh to re-read
                        weDirs.refresh()
                    }
                }

                // List workshop subfolders (each is a wallpaper item)
                FolderListModel {
                    id: weDirs
                    folder: workshopUrl
                    showDirs: true
                    showFiles: false
                    showHidden: false
                    showOnlyReadable: true
                    nameFilters: ["*"]
                }

                // Selection state
                property var selected: ({})
                function toggleSelected(key, value) {
                    if (selected[key]) delete selected[key]; else selected[key] = value
                }

                // Helper note
                Label { text: qsTr("Select your Steam directory to load Wallpaper Engine Workshop items (app 431960)." ); wrapMode: Text.WordWrap; opacity: 0.7 }

                // Grid of workshop items
                GridView {
                    id: weView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    cellWidth: 180
                    cellHeight: 140
                    visible: workshopUrl !== ""
                    model: workshopUrl !== "" ? weDirs : null
                    delegate: Frame {
                        width: 170; height: 130
                        visible: (typeof fileIsDir !== 'undefined' ? fileIsDir : (typeof isFolder !== 'undefined' ? isFolder : true))
                        property string dirUrl: toStringUrl(typeof fileURL !== 'undefined' ? fileURL : (typeof fileUrl !== 'undefined' ? fileUrl : filePath))
                        property string title: meta && meta.title ? meta.title : fileName
                        property string type: meta && meta.type ? meta.type : ""
                        property string previewUrl: meta && meta.preview ? joinUrl(dirUrl, meta.preview) : ""
                        property string videoUrl: meta && meta.file ? joinUrl(dirUrl, meta.file) : ""
                        property var meta: null

                        background: Rectangle { radius: 6; border.color: Kirigami.Theme.textColor; border.width: 1; color: "transparent" }
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            Item {
                                Layout.fillWidth: true; Layout.preferredHeight: 90
                                Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; source: previewUrl }
                                CheckBox {
                                    id: sel
                                    anchors.top: parent.top; anchors.right: parent.right
                                    checked: !!root.selected[dirUrl]
                                    onClicked: root.toggleSelected(dirUrl, { previewUrl: previewUrl, videoUrl: videoUrl, title: title })
                                }
                            }
                            Label { text: title; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label { text: type; opacity: 0.6 }
                        }

                        Component.onCompleted: {
                            // Load meta from project.json
                            var xhr = new XMLHttpRequest()
                            xhr.open('GET', joinUrl(dirUrl, 'project.json'))
                            xhr.onreadystatechange = function() {
                                if (xhr.readyState === XMLHttpRequest.DONE) {
                                    try {
                                        meta = JSON.parse(xhr.responseText)
                                    } catch (e) { /* ignore */ }
                                }
                            }
                            xhr.send()
                        }
                    }
                }

                // Empty state
                Label {
                    visible: workshopUrl !== "" && weDirs.count === 0
                    text: qsTr("No Workshop items found in %1").arg(workshopUrl)
                    opacity: 0.7
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
}

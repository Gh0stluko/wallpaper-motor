import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import org.kde.kirigami 2.20 as Kirigami

// Configuration UI for the wallpaper plugin
ColumnLayout {
    id: root
    
    property QtObject configDialog
    property QtObject wallpaperConfiguration
    
    property string cfg_playlist
    property alias cfg_intervalSeconds: intervalField.value
    property alias cfg_crossfadeMs: crossfadeField.value
    property alias cfg_shuffle: shuffleCheck.checked

    // Model storing selected files
    ListModel { id: playlistModel }

    // Convert comma-separated string to array
    function playlistFromString(str) {
        if (!str || str.length === 0) return []
        return str.split(',').filter(function(s) { return s.trim().length > 0 })
    }

    // Convert array to comma-separated string
    function playlistToString(arr) {
        return arr.join(',')
    }

    Component.onCompleted: {
        // Initial load from saved config - ONLY load once here
        var arr = playlistFromString(cfg_playlist)
        for (var i = 0; i < arr.length; ++i) {
            playlistModel.append({ url: arr[i] })
        }
    }

    function updatePlaylist() {
        var out = []
        for (var i = 0; i < playlistModel.count; ++i) {
            out.push(playlistModel.get(i).url)
        }
        cfg_playlist = playlistToString(out)
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Add images to playlist")
        fileMode: FileDialog.OpenFiles
        nameFilters: [
            qsTr("Images (*.png *.jpg *.jpeg *.gif *.bmp *.webp *.avif)")
        ]
        onAccepted: {
            // In Qt6, selectedFiles is a list of urls (QUrl)
            for (var i = 0; i < fileDialog.selectedFiles.length; ++i) {
                var u = fileDialog.selectedFiles[i]
                var s = typeof u === 'string' ? u : u.toString()
                playlistModel.append({ url: s })
            }
            updatePlaylist()
        }
    }

    Kirigami.Heading { text: qsTr("Playlist"); level: 3; Layout.fillWidth: true }

    RowLayout {
        spacing: 8
        Layout.fillWidth: true
        Button { text: qsTr("Add"); onClicked: fileDialog.open() }
        Button { text: qsTr("Remove selected"); enabled: view.currentIndex >= 0; onClicked: {
                if (view.currentIndex >= 0) {
                    playlistModel.remove(view.currentIndex)
                    updatePlaylist()
                }
            } }
        Button { text: qsTr("Move up"); enabled: view.currentIndex > 0; onClicked: {
                var i = view.currentIndex
                var item = playlistModel.get(i)
                playlistModel.remove(i)
                playlistModel.insert(i-1, item)
                view.currentIndex = i-1
                updatePlaylist()
            } }
        Button { text: qsTr("Move down"); enabled: view.currentIndex >= 0 && view.currentIndex < playlistModel.count-1; onClicked: {
                var i = view.currentIndex
                var item = playlistModel.get(i)
                playlistModel.remove(i)
                playlistModel.insert(i+1, item)
                view.currentIndex = i+1
                updatePlaylist()
            } }
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
            from: 0; to: 10000; value: 800
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

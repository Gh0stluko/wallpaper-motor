import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
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

        // Wallpaper Engine page (placeholder)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                Kirigami.Heading { text: qsTr("Wallpaper Engine"); level: 3 }
                Label { text: qsTr("Coming soon: import and manage animated wallpapers.") }
                Label { text: qsTr("For now, use the Photo tab to configure a slideshow.") }
                Item { Layout.fillHeight: true }
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

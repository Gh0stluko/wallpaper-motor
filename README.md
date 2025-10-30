# Wallpaper Engine (KDE Plasma 6)

A KDE Plasma 6 wallpaper plugin that provides a playlist with previews and a smooth crossfade transition.

Note: Plasma wallpaper plugins are implemented in QML/KPackage. This project ships a QML plugin and a small Python installer.

## Features

- Playlist of images with thumbnail preview in the config dialog
- Smooth crossfade transition between images
- Interval and shuffle options
- Supports common image formats: PNG, JPG/JPEG, GIF, BMP, WebP, AVIF (as supported by your Qt build)

Tested target: KDE Plasma 6.5.1

## Install

Use the Python installer to copy the plugin into your user wallpapers directory.

```bash
python3 tools/install.py
```

If the plugin does not appear in the Wallpaper Type menu, restart Plasma:

```bash
kquitapp6 plasmashell && kstart6 plasmashell
```

## Use

- Right-click the desktop → Configure Desktop and Wallpaper…
- Wallpaper Type: select "Wallpaper Engine"
- Use the Playlist section to add images, reorder them, and set interval/crossfade.

## Notes

- Plasma does not execute Python code inside wallpaper plugins. The runtime is QML/JavaScript (with QtQuick), so the plugin itself is QML. Python is used here for tooling (installer) and can be used for future helpers.
- Future work: add a dedicated Python/Kirigami management app; add support for importing from Wallpaper Engine collections.

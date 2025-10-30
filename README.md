# Wallpaper Engine (KDE Plasma 6)

A KDE Plasma 6 wallpaper plugin that provides a playlist with previews and a smooth crossfade transition.

Note: Plasma wallpaper plugins are implemented in QML/KPackage. This project ships a QML plugin and a small Python installer.

## Features

- **Photo Playlist Mode**: Playlist of images with thumbnail preview in the config dialog
- **Wallpaper Engine Support**: Import and display animated wallpapers from Steam Workshop
- Smooth crossfade transition between images
- Interval and shuffle options for playlists
- Video wallpaper support for Wallpaper Engine items
- Supports common image formats: PNG, JPG/JPEG, GIF, BMP, WebP, AVIF (as supported by your Qt build)

Tested target: KDE Plasma 6.5.1

## Install

Use the Python installer to copy the plugin into your user wallpapers directory.

```bash
python3 tools/install.py
```

### Wallpaper Engine Support Setup

To use Wallpaper Engine wallpapers, you need to configure QML file reading permissions:

```bash
./tools/setup_wallpaper_engine.sh
```

Then restart plasmashell or log out and back in. See [WALLPAPER_ENGINE_SETUP.md](WALLPAPER_ENGINE_SETUP.md) for details.

If the plugin does not appear in the Wallpaper Type menu, restart Plasma:

```bash
kquitapp6 plasmashell && kstart6 plasmashell
```

## Use

- Right-click the desktop → Configure Desktop and Wallpaper…
- Wallpaper Type: select "Wallpaper Engine"

### Photo Mode
- Use the **Photo** tab to add images, reorder them, and set interval/crossfade.

### Wallpaper Engine Mode
- Use the **Wallpaper Engine** tab to import animated wallpapers from Steam
- Enter your Steam directory (e.g., `/home/user/.local/share/Steam`)
- Click **Scan** to search for Wallpaper Engine workshop items
- Browse available wallpapers and click to select one
- Supports both video (.mp4) and image wallpapers from Workshop ID 431960

## Debugging and dev loop

If UI doesn’t show or you want quick iteration, use these helpers:

- Live logs (QML/Qt warnings and errors):

	```bash
	./tools/logs.sh
	```

- One-shot reinstall + restart Plasma shell (reload QML):

	```bash
	./tools/reload.sh
	```

- Watch for file changes and auto-reload:

	```bash
	# Requires: inotify-tools (sudo apt install inotify-tools)
	./tools/watch.sh
	```

Additional tips:

- Validate QML syntax statically with qmllint (from qt6-declarative-tools):

	```bash
	qmllint wallpaper-engine/contents/ui/main.qml
	qmllint wallpaper-engine/contents/ui/config.qml
	```

- For immediate logs without journalctl, run plasmashell in a terminal session temporarily:
	- Switch to a TTY or open Konsole, then run: `plasmashell --replace` (your desktop will restart and logs will stream in that terminal). Press Ctrl-C to stop and restore via `kstart6 plasmashell`.

- Common issues if UI doesn’t render:
	- Root item must be `WallpaperItem` on Plasma 6 (this project uses it).
	- Config keys in QML must match `contents/config/main.xml` (`configuration.playlist`, `intervalSeconds`, etc.).
	- Image sources should be valid URLs (e.g., file:///home/user/Pictures/a.jpg). The config dialog saves file URLs.
	- After updating files, reinstall and restart (use scripts above). Plasma caches packages aggressively.

## Notes

- Plasma does not execute Python code inside wallpaper plugins. The runtime is QML/JavaScript (with QtQuick), so the plugin itself is QML. Python is used here for tooling (installer) and can be used for future helpers.
- Future work: add a dedicated Python/Kirigami management app; add support for importing from Wallpaper Engine collections.

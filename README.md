# Wallpaper Engine (KDE Plasma 6)

A KDE Plasma 6 wallpaper plugin that supports both photo playlists and Wallpaper Engine animated wallpapers from Steam Workshop.

## Features

- **Photo Playlist Mode**: Create slideshows with smooth crossfade transitions
- **Wallpaper Engine Support**: Import and display animated wallpapers from Steam Workshop
- Smooth crossfade transition between images
- Interval and shuffle options for playlists
- Video wallpaper support (mp4, webm)
- Scene wallpaper support (static Wallpaper Engine items)
- Supports common image formats: PNG, JPG/JPEG, GIF, BMP, WebP, AVIF

Tested on: KDE Plasma 6.5.1, Arch Linux

## Requirements

- KDE Plasma 6.x
- Python 3
- Qt 6 with QtMultimedia
- For Wallpaper Engine: Steam with Wallpaper Engine workshop items

## Installation

### 1. Clone or Download

```bash
git clone https://github.com/Gh0stluko/wallpaperkde.git
cd wallpaperkde
```

### 2. Install the Plugin

```bash
python3 tools/install.py
```

### 3. Setup for Wallpaper Engine (Required for WE wallpapers)

Run the setup script to enable QML file reading:

```bash
./tools/setup_wallpaper_engine.sh
```

This creates a systemd service override that allows the plugin to read Wallpaper Engine project files.

### 4. Restart Plasma

```bash
kquitapp6 plasmashell && kstart6 plasmashell
```

Or log out and log back in to KDE.

## Usage

### Initial Setup

1. Right-click the desktop → **Configure Desktop and Wallpaper...**
2. **Wallpaper Type** → select **"Wallpaper Engine"**

### Photo Mode

1. Go to the **Photo** tab
2. Click **"Use this mode"** to activate photo playlist mode
3. Click **"Add"** to select images
4. Configure interval, crossfade duration, and shuffle
5. Reorder images using Move up/down buttons

### Wallpaper Engine Mode

1. Go to the **Wallpaper Engine** tab  
2. Click **"Use this mode"** to activate Wallpaper Engine mode
3. Enter your Steam directory (e.g., `/home/user/.local/share/Steam`)
4. Click **"Scan"** to search for wallpapers
5. Click on a wallpaper thumbnail to select it
6. The wallpaper will be applied immediately

### Switching Between Modes

You can switch between Photo and Wallpaper Engine modes at any time using the **"Use this mode"** button in each tab. The active mode is marked with **✓ Active**.

## Troubleshooting

### Plugin doesn't appear in Wallpaper Type menu

```bash
kquitapp6 plasmashell && kstart6 plasmashell
```

### Wallpaper Engine wallpapers don't load

Make sure you ran the setup script:
```bash
./tools/setup_wallpaper_engine.sh
```

Then restart plasmashell or log out/in.

### Video wallpapers have poor performance

- Enable hardware video decoding in your system
- Use 1080p wallpapers instead of 4K
- Consider using scene wallpapers (static) instead of video

### Check if hardware acceleration is available

```bash
# For Intel/AMD
vainfo

# For NVIDIA
nvidia-smi
```

## Performance

**Photo Mode:**
- CPU: ~0-2%
- RAM: ~5-20 MB
- Very lightweight, suitable for any PC

**Wallpaper Engine Video Mode:**
- CPU: 2-30% (depends on hardware decoding)
- RAM: 50-200 MB
- With hardware decoding: minimal impact
- Without hardware decoding: moderate impact

**Tips:**
- Photo mode is the most lightweight option
- Scene wallpapers consume less than videos
- Hardware decoding significantly reduces CPU usage
- Use 1080p instead of 4K for better performance

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

## Project Structure

```
wallpaperkde/
├── wallpaper-engine/          # Main plugin directory
│   ├── contents/
│   │   ├── config/
│   │   │   ├── config.qml     # Config UI tabs
│   │   │   └── main.xml       # Configuration schema
│   │   ├── ui/
│   │   │   ├── config.qml     # Configuration interface
│   │   │   └── main.qml       # Wallpaper display logic
│   │   └── code/
│   │       └── scan_wallpapers.py  # WE scanner
│   └── metadata.json          # Plugin metadata
├── tools/
│   ├── install.py                    # Installation script
│   ├── setup_wallpaper_engine.sh     # WE setup
│   ├── reload.sh                     # Quick reload
│   ├── watch.sh                      # Auto-reload
│   └── logs.sh                       # View logs
└── README.md
```

## For Other Distributions

### Debian/Ubuntu

```bash
# Install dependencies
sudo apt install python3 qt6-declarative-dev inotify-tools

# Install plugin
python3 tools/install.py
./tools/setup_wallpaper_engine.sh

# Restart
kquitapp6 plasmashell && kstart6 plasmashell
```

### Fedora

```bash
# Install dependencies
sudo dnf install python3 qt6-qtdeclarative-devel inotify-tools

# Install plugin
python3 tools/install.py
./tools/setup_wallpaper_engine.sh

# Restart
kquitapp6 plasmashell && kstart6 plasmashell
```

### openSUSE

```bash
# Install dependencies
sudo zypper install python3 qt6-declarative-devel inotify-tools

# Install plugin
python3 tools/install.py
./tools/setup_wallpaper_engine.sh

# Restart
kquitapp6 plasmashell && kstart6 plasmashell
```

## Contributing

Contributions welcome! Please:
1. Test changes with `./tools/reload.sh`
2. Validate QML with `qmllint`
3. Check logs with `./tools/logs.sh`
4. Update documentation as needed

## License

MIT License

## Author

Created by gluko

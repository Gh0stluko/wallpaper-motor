# Quick Start Guide

## For End Users (Simple Installation)

### Step 1: Download

```bash
git clone https://github.com/yourusername/wallpaperkde.git
cd wallpaperkde
```

Or download ZIP from GitHub and extract it.

### Step 2: Install

```bash
# Run installer
python3 tools/install.py

# Setup Wallpaper Engine support (needed for animated wallpapers)
./tools/setup_wallpaper_engine.sh

# Restart Plasma
kquitapp6 plasmashell && kstart6 plasmashell
```

### Step 3: Configure

1. Right-click desktop → **Configure Desktop and Wallpaper**
2. **Wallpaper Type** → select **"Wallpaper Engine"**
3. Choose mode:
   - **Photo tab**: For image slideshows
   - **Wallpaper Engine tab**: For animated wallpapers from Steam

Done! 🎉

## FAQ

**Q: Do I need Wallpaper Engine from Steam?**  
A: Only if you want to use animated wallpapers. Photo mode works without it.

**Q: Where are Wallpaper Engine wallpapers?**  
A: They're in your Steam Workshop folder: `~/.local/share/Steam/steamapps/workshop/content/431960/`

**Q: Can I use both Photo and Wallpaper Engine modes?**  
A: Yes! Switch between them using the "Use this mode" button in each tab.

**Q: Performance impact?**  
A: Photo mode: negligible (~2% CPU). WE videos: 2-30% CPU depending on hardware decoding.

**Q: It doesn't work after installation?**  
A: Make sure you ran `setup_wallpaper_engine.sh` and restarted plasmashell.

**Q: Black screen when selecting wallpaper?**  
A: Check logs: `./tools/logs.sh` and make sure the setup script was run.

**Q: How to uninstall?**  
A: Delete `~/.local/share/plasma/wallpapers/wallpaper-engine/` and remove the systemd override: `rm -rf ~/.config/systemd/user/plasma-plasmashell.service.d/wallpaper-engine.conf`

## System Requirements

**Minimum:**
- KDE Plasma 6.0+
- Python 3.6+
- Qt 6 with QtMultimedia

**Recommended:**
- KDE Plasma 6.5+
- Hardware video decoding (Intel QSV, AMD VCE, or NVIDIA NVDEC)
- For WE: Steam with Wallpaper Engine installed

## Distribution-Specific Notes

### Arch Linux
```bash
sudo pacman -S python qt6-multimedia inotify-tools
```

### Ubuntu/Debian
```bash
sudo apt install python3 qt6-multimedia-dev inotify-tools
```

### Fedora
```bash
sudo dnf install python3 qt6-qtmultimedia-devel inotify-tools
```

## Need Help?

1. Check logs: `./tools/logs.sh`
2. Read full documentation: [README.md](README.md)
3. Wallpaper Engine setup: [WALLPAPER_ENGINE_SETUP.md](WALLPAPER_ENGINE_SETUP.md)
4. Open an issue on GitHub

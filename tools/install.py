#!/usr/bin/env python3
import os
import shutil
from pathlib import Path

PLUGIN_ID = "wallpaper-engine"
SRC_ROOT = Path(__file__).resolve().parents[1] / PLUGIN_ID
DEST_ROOT = Path.home() / ".local/share/plasma/wallpapers" / PLUGIN_ID


def copytree(src: Path, dst: Path):
    if dst.exists():
        shutil.rmtree(dst)
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(src, dst)


def main():
    if not SRC_ROOT.exists():
        print(f"Source plugin not found: {SRC_ROOT}")
        return 1
    copytree(SRC_ROOT, DEST_ROOT)
    print(f"Installed plugin to: {DEST_ROOT}")
    print("Now open Desktop Settings → Wallpaper → Wallpaper Type and select 'Wallpaper Engine'.")
    print("If it does not appear, try restarting plasmashell: 'kquitapp6 plasmashell && kstart6 plasmashell'")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

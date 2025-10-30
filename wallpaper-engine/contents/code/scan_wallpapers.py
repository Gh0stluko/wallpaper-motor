#!/usr/bin/env python3
"""
Scan Wallpaper Engine workshop directory and output wallpaper data as JSON.
Usage: scan_wallpapers.py <steam_directory>
"""

import json
import sys
from pathlib import Path


def scan_wallpapers(steam_dir):
    """Scan Wallpaper Engine workshop content directory."""
    workshop_path = Path(steam_dir) / "steamapps/workshop/content/431960"
    
    if not workshop_path.exists():
        return []
    
    wallpapers = []
    
    for folder in workshop_path.iterdir():
        if not folder.is_dir():
            continue
        
        project_file = folder / "project.json"
        if not project_file.exists():
            continue
        
        try:
            with open(project_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            preview_path = str(folder / data.get('preview', 'preview.gif'))
            file_path = str(folder / data['file'])
            
            wallpapers.append({
                'id': folder.name,
                'title': data.get('title', folder.name),
                'preview': preview_path,
                'file': file_path,
                'type': data.get('type', 'unknown'),
                'description': data.get('description', '')
            })
        except Exception as e:
            print(f"Error reading {folder.name}: {e}", file=sys.stderr)
            continue
    
    return wallpapers


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: scan_wallpapers.py <steam_directory>", file=sys.stderr)
        sys.exit(1)
    
    steam_dir = sys.argv[1]
    wallpapers = scan_wallpapers(steam_dir)
    print(json.dumps(wallpapers))

# Wallpaper Engine Setup

## Налаштування для роботи з Wallpaper Engine

Для сканування Wallpaper Engine шпалер з Steam Workshop потрібно дозволити QML читати локальні файли.

### Автоматичне налаштування (рекомендується)

Запустіть скрипт налаштування:

```bash
./tools/setup_wallpaper_engine.sh
```

Або налаштуйте вручну:

### Ручне налаштування

#### Варіант 1: Systemd Service Override (постійне рішення)

```bash
mkdir -p ~/.config/systemd/user/plasma-plasmashell.service.d/
cat > ~/.config/systemd/user/plasma-plasmashell.service.d/wallpaper-engine.conf << 'EOF'
[Service]
Environment="QML_XHR_ALLOW_FILE_READ=1"
EOF

systemctl --user daemon-reload
systemctl --user restart plasma-plasmashell
```

#### Варіант 2: Глобальна змінна середовища

Додайте в `~/.config/plasma-workspace/env/wallpaper-engine.sh`:

```bash
mkdir -p ~/.config/plasma-workspace/env/
cat > ~/.config/plasma-workspace/env/wallpaper-engine.sh << 'EOF'
#!/bin/sh
export QML_XHR_ALLOW_FILE_READ=1
EOF

chmod +x ~/.config/plasma-workspace/env/wallpaper-engine.sh
```

Потім вийдіть і увійдіть знову в KDE.

#### Варіант 3: Тимчасове рішення (тільки для поточної сесії)

```bash
export QML_XHR_ALLOW_FILE_READ=1
kquitapp6 plasmashell
kstart6 plasmashell
```

## Використання

1. Відкрийте налаштування робочого столу (ПКМ → Configure Desktop and Wallpaper)
2. Wallpaper Type → виберіть "Wallpaper Engine"
3. Перейдіть на вкладку "Wallpaper Engine"
4. Вкажіть шлях до Steam (наприклад: `/home/user/.local/share/Steam`)
5. Натисніть "Scan"
6. Виберіть шпалеру зі списку

## Примітки

- Змінна `QML_XHR_ALLOW_FILE_READ` дозволяє QML читати JSON файли з локальної файлової системи
- Це безпечно в контексті Plasma wallpaper plugin
- Qt планує видалити цю можливість в майбутніх версіях, тому можливо знадобиться альтернативне рішення

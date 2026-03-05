# 📚 ReadMastery - Gamify Your Reading

**ReadMastery** is a KOReader plugin that transforms your reading experience into an RPG-style adventure. Earn XP, level up, maintain streaks, and unlock achievements as you read!

![KOReader](https://img.shields.io/badge/KOReader-Plugin-blue)
![Lua](https://img.shields.io/badge/Language-Lua-purple)
![License](https://img.shields.io/badge/License-MIT-green)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?style=flat&logo=buy-me-a-coffee)](https://www.buymeacoffee.com/lalocaballero)

---

## ✨ Features

### 🎮 Core Mechanics

| Feature | Description |
|---------|-------------|
| **XP System** | Earn XP for every page turned and every minute spent reading |
| **Leveling** | Level up as you gain XP (Levels 1-20+) |
| **Daily Streaks** | Build consecutive reading days |
| **Freeze Tokens** | Earn tokens every 7 days to protect your streak |

### 🏆 11 Achievements

Unlock badges as you reach milestones:

| Badge | Name | Requirement |
|-------|------|-------------|
| ☀️ | **Early Bird** | Read between 4:00 AM - 7:00 AM |
| 🌙 | **Night Owl** | Read between 12:00 AM - 4:00 AM |
| ⚔️ | **Weekend Warrior** | Read 100+ pages on Saturday or Sunday |
| 💯 | **The Centurion** | Read 100 pages in a single session |
| 🏃 | **Marathon** | Read for 3 hours continuously |
| ⚡ | **Sprint** | Read 50 pages in under 30 minutes |
| 🗺️ | **Format Explorer** | Read 3 different file formats |
| 📖 | **Book Slayer** | Finish a book (95% completion) |
| 🦸 | **Paperback Hero** | Read 1,000 lifetime pages |
| 📚 | **Bibliophile** | Read 5,000 lifetime pages |
| 👑 | **Literary Legend** | Read 10,000 lifetime pages |

### 📊 Progressive Feature Unlocks

Analytics features unlock as you level up:

| Level | Unlock |
|-------|--------|
| 1-2 | Basic stats (Level, XP, Streak) |
| 3 | **Session Stats** - Current session duration & pages |
| 5 | **7-Day Heatmap** - Visual reading intensity chart |
| 7 | **Weekly Digest** - Weekly summary with rank |
| 10 | **Speed Analytics** - Reading speed & style analysis |
| 15 | **Completion Rate** - Books started vs. finished |
| 20 | **Hall of Fame** - All-time records & achievements |

---

## 📋 Changelog

### v1.3.1 (2026-03-05)

#### Bug Fixes

- **Fixed ProjectTitle footer integration** (#11): The previous patch-based approach for PT footer didn't work reliably because patches load before plugins, causing timing issues. Replaced with a modified `covermenu_readmastery.lua` that users copy directly into ProjectTitle's plugin folder. This adds ReadMastery stats directly into PT's footer rendering pipeline, ensuring it works on every page load, pagination, and folder navigation.

#### Changes

- Removed deprecated `2-projecttitle-footer-readmastery.lua` patch file
- PT footer integration now uses a modified `covermenu.lua` approach (more reliable)
- Updated installation instructions for PT footer setup
- Version bumped to 1.3.1

---

### v1.3.0 (2026-03-02)

#### Bug Fixes

- **Fixed crash with CBZ/comic files** (#8, #3): The plugin no longer crashes when opening CBZ or other document types that don't support `getCurrentPage()`. All page-related calls are now safely wrapped with error handling, enabling full tracking support for comic book archives and other formats.

- **Fixed Random Page triggering multiple achievements** (#5): Using the "Random Page" feature (or any large page jump via TOC, bookmarks, etc.) no longer falsely counts hundreds of pages as read. Large jumps (>5 pages) are detected and excluded from page tracking. Additionally, time-based achievements (Early Bird, Night Owl, Weekend Warrior) now only count once per day, and session achievements (Centurion, Marathon, Sprint) only trigger once per session.

- **Fixed streak reset on book finish** (#7): Finishing a book no longer incorrectly resets the reading streak. The streak logic now properly handles midnight crossover sessions (starting a book before midnight and finishing after) and correctly calculates missed days.

- **Fixed ASCII art distortion in landscape mode** (#10): Achievement and tier-up popups now use the dedicated `AsciiPopup` widget with monospace font rendering. The popup automatically detects screen orientation and adjusts its width (60% in landscape vs 85% in portrait) and font size to keep ASCII art properly aligned on all screen orientations.

- **Fixed streak reset on orientation change** (#10): Changing device orientation (portrait ↔ landscape) no longer triggers a session restart. The plugin now detects when `onReaderReady` is called for an already-active session on the same document and skips re-initialization.

#### Improvements

- Added safe page detection for all document types using `pcall` wrappers
- Achievement notifications now use the `AsciiPopup` widget for better rendering
- Daily deduplication for time-based achievement progress tracking
- Session-level deduplication for continuous reading achievements
- More robust streak continuation logic with freeze token awareness
- File extension parsing is now nil-safe for documents without extensions

#### New Features

- **ProjectTitle Footer Support** (#9): ReadMastery stats can now be displayed in the Project: Title plugin's footer bar. Ships with a modified `covermenu_readmastery.lua` that replaces PT's original `covermenu.lua`. Includes a new "Level + XP" display format (e.g., `Lv11 XP 514/687`). Configure via ReadMastery → Display → ProjectTitle Footer.

---

## 📥 Installation

### Method 1: Direct Download

1. Download the `ReadMastery.koplugin` folder
2. Copy it to your KOReader plugins directory:
   - **Kindle**: `/koreader/plugins/`
   - **Kobo**: `/.adds/koreader/plugins/`
   - **Android**: `/sdcard/koreader/plugins/`
   - **Desktop**: `~/.config/koreader/plugins/`
3. Restart KOReader

### Method 2: Git Clone

```bash
cd /path/to/koreader/plugins/
git clone https://github.com/YOUR_USERNAME/ReadMastery.koplugin.git
```

### Optional: ProjectTitle Footer Integration

If you use the [Project: Title](https://github.com/joshuacant/ProjectTitle.koplugin) plugin and want ReadMastery stats in the footer:

1. Find `covermenu_readmastery.lua` inside the ReadMastery plugin folder
2. Copy it to your ProjectTitle plugin directory:
   - **Kindle**: `/koreader/plugins/projecttitle.koplugin/`
   - **Kobo**: `/.adds/koreader/plugins/projecttitle.koplugin/`
   - **Android**: `/sdcard/koreader/plugins/projecttitle.koplugin/`
3. **Rename** `covermenu_readmastery.lua` to `covermenu.lua` (replacing ProjectTitle's original file)
4. Restart KOReader

> **Note:** This replaces ProjectTitle's `covermenu.lua` with a version that includes ReadMastery support. If you update ProjectTitle in the future, you may need to repeat this step. We recommend keeping a backup of the original `covermenu.lua`.

5. Configure the display format in **ReadMastery → Display → ProjectTitle Footer**

Available display formats:

| Format | Example |
|--------|---------|
| Streak Only | `~5` |
| Level Only | `Lv3` |
| Streak + Level | `~5 Lv3` |
| Level + XP | `Lv11 XP 514/687` |
| Full | `~5 Lv3 42pg` |

> **Tip:** If you also use the [footer widgets patch](https://github.com/joshuacant/KOReader.patches/blob/main/2-reader-footer-widgets.lua), you can add `"readmastery"` to its `order` table to control where ReadMastery appears in the footer.

---

## 📁 Plugin Structure

```
ReadMastery.koplugin/
├── _meta.lua              # Plugin metadata
├── main.lua               # Entry point & event handlers
├── readmasterycore.lua    # Data management & persistence
├── xpengine.lua           # XP calculations
├── streakmanager.lua      # Streak & freeze token logic
├── achievements.lua       # Achievement definitions & checks
├── analytics.lua          # Statistics calculations
├── featureunlocks.lua     # Level-based feature unlocking
├── icons.lua              # ASCII icon definitions
├── ascii_art.lua          # Achievement ASCII art
├── titlebar_integration.lua   # Title bar patch integration
├── 2-filemanager-titlebar.lua # Title bar patch (copy to patches/)
├── covermenu_readmastery.lua  # Modified PT covermenu (replace PT's covermenu.lua)
└── ui/
    ├── mainmenu.lua       # Main menu interface
    ├── statsview.lua      # Quick stats display
    ├── achievements_view.lua  # Achievements list
    ├── ascii_popup.lua    # ASCII art popup widget
    └── notifications.lua  # Level up & achievement popups
```

---

## 🎯 Usage

### Accessing the Plugin

1. Open KOReader
2. Go to **Menu** → **Tools** → **ReadMastery**

### Menu Options

| Option | Description |
|--------|-------------|
| **View Stats** | See your current level, XP, streak, and progress |
| **Achievements** | Browse all 11 achievements (tap to see details) |
| **Streak Info** | Detailed streak and freeze token information |
| **Analytics** | Access unlocked analytics features |
| **Settings** | Sandbox mode, debug mode, reset progress |

### Settings

| Setting | Description |
|---------|-------------|
| **Sandbox Mode** | Temporarily unlocks all features for testing |
| **Reset Progress** | Permanently deletes all data (use with caution!) |

---

## 📈 XP System

### Earning XP

| Action | XP Earned |
|--------|-----------|
| Per page turned | 5 XP |
| Per minute reading | 2 XP |
| Achievement bonus | 50-1000 XP |

### Streak Multiplier

Consecutive reading days boost your XP:

| Streak | Multiplier |
|--------|------------|
| 0 days | 1.0x |
| 5 days | 1.25x |
| 10 days | 1.5x |
| 20 days | 2.0x (max) |

### Level Progression

XP required increases with each level:

| Level | Total XP Required |
|-------|-------------------|
| 2 | 100 XP |
| 3 | 250 XP |
| 5 | 625 XP |
| 10 | 2,375 XP |
| 20 | 9,500 XP |

---

## 🔥 Streak System

| Feature | Description |
|---------|-------------|
| **Building Streaks** | Read any amount each day to maintain your streak |
| **Freeze Tokens** | Earned every 7 consecutive days |
| **Token Usage** | Automatically consumed if you miss a day |
| **Streak Reset** | Missing a day without a token resets streak to 0 |

---

## 🛠️ Development

### Requirements

| Requirement | Version |
|-------------|---------|
| KOReader | Any recent version |
| Lua | 5.1 / LuaJIT |

### Data Storage

User data is stored in JSON format:

```
/koreader/data/readmastery/readmastery_data.json
```

### Adding Custom ASCII Art

Edit `ascii_art.lua` to customize achievement artwork:

```lua
AsciiArt.large = {
    your_achievement = [[

        Your ASCII art here
        Keep it under 48 characters wide
        for best display on e-readers

    ]],
}
```

### ASCII Art Tips

| Do | Don't |
|----|-------|
| Use spaces for background | Use dots (.) - they're too narrow |
| Keep width under 48 chars | Make overly complex designs |
| Use # @ % for filled areas | Use unicode characters |
| Test on actual device | Assume it will look the same |

---

## 🤝 Contributing

Contributions are welcome! Here's how:

1. Fork the repository
2. Create a feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit your changes
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. Push to the branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. Open a Pull Request

### Ideas for Contributions

- [ ] Daily/weekly reading goals
- [ ] Reading challenges
- [ ] Export stats to file
- [ ] Multiple user profiles
- [ ] Custom achievement creation
- [ ] Integration with reading lists
- [ ] Localization / translations
- [ ] Sound effects (for supported devices)

---

## 📝 License

This project is licensed under the MIT License.

```
MIT License

Copyright (c) 2024 YOUR_NAME

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

| | |
|---|---|
| [KOReader](https://github.com/koreader/koreader) | The amazing open-source ebook reader |
| KOReader Community | Documentation and plugin examples |
| Contributors | Everyone who helps improve this plugin |

---

## 📬 Contact

| Channel | Link |
|---------|------|
| **Issues** | [GitHub Issues](https://github.com/Lalocaballero/ReadMastery.koplugin/issues) |
| **Discussions** | [GitHub Discussions](https://github.com/Lalocaballero/ReadMastery.koplugin/discussions) |

---
## 📸 Screenshots

### Plugin Location & Main Menu

<table>
  <tr>
    <th>Tools Menu</th>
    <th>ReadMastery Menu</th>
  </tr>
  <tr>
    <td><img src="screenshots/01Tools.png" width="300" alt="Tools Menu"></td>
    <td><img src="screenshots/02menu.png" width="300" alt="ReadMastery Menu"></td>
  </tr>
  <tr>
    <td><i>Find ReadMastery under Tools</i></td>
    <td><i>Main plugin menu</i></td>
  </tr>
</table>

### Stats & Achievements

<table>
  <tr>
    <th>Stats View</th>
    <th>Achievements</th>
  </tr>
  <tr>
    <td><img src="screenshots/03stats.png" width="300" alt="Stats View"></td>
    <td><img src="screenshots/04achievements.png" width="300" alt="Achievements"></td>
  </tr>
  <tr>
    <td><i>Level, XP, Streak info</i></td>
    <td><i>11 unlockable badges</i></td>
  </tr>
</table>

### Analytics Features

<table>
  <tr>
    <th>Analytics Menu</th>
    <th>7-Day Heatmap</th>
  </tr>
  <tr>
    <td><img src="screenshots/05analytics.png" width="300" alt="Analytics Menu"></td>
    <td><img src="screenshots/06heatmap.png" width="300" alt="Heatmap"></td>
  </tr>
  <tr>
    <td><i>Unlocks as you level up</i></td>
    <td><i>Visual reading intensity</i></td>
  </tr>
</table>

### Settings & Info

<table>
  <tr>
    <th>Settings</th>
    <th>About</th>
  </tr>
  <tr>
    <td><img src="screenshots/07settings.png" width="300" alt="Settings"></td>
    <td><img src="screenshots/08info.png" width="300" alt="About"></td>
  </tr>
  <tr>
    <td><i>Sandbox, Reset</i></td>
    <td><i>Plugin information</i></td>
  </tr>
</table>
---

<p align="center">
  <b>Happy Reading! 📚✨</b>
  <br><br>
  <i>Every page counts towards your next level!</i>
  <br><br>
  ⭐ Star this repo if you find it useful! ⭐
  <br><br>
  <a href="https://www.buymeacoffee.com/lalocaballero">
    <img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?style=flat&logo=buy-me-a-coffee" alt="Buy Me A Coffee">
  </a>
</p>
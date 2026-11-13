# MediaKeysFix for macOS

<p align="center">
  <img src="resources/AppIcon.icns" width="128" height="128" alt="MediaKeysFix Icon" />
</p>

<p align="center">
  <strong>The ultra-fast, hardware-level media keys fix for physical F7, F8, and F9 keys on macOS.</strong><br>
  Built as a lightweight native Menu Bar app with one-click Start at Login and zero Accessibility permissions.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2011%2B-black.svg" alt="Platform: macOS 11+">
  <img src="https://img.shields.io/badge/arch-Apple%20Silicon%20%7C%20Intel-blue.svg" alt="Architecture: Apple Silicon | Intel">
  <img src="https://img.shields.io/badge/language-Swift%206-orange.svg" alt="Language: Swift">
  <img src="https://img.shields.io/badge/permissions-Zero%20Accessibility-brightgreen.svg" alt="Zero Accessibility Permissions">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT">
</p>

---

## 🎧 Why Was This Created?

On modern macOS, controlling media using the physical top-row keys (**F7** Previous, **F8** Play/Pause, **F9** Next) on MacBook Pro, MacBook Air, and Magic Keyboards frequently fails or behaves erratically—especially with web players (YouTube Music PWA, SoundCloud, Spotify, Safari, Chrome):

1. **WebKit 86ms State Bounce:** When pressing `F8`, WebKit receives an event from `mediaremoted` and an internal JS event simultaneously, causing playback to pause and immediately resume within ~80 milliseconds.
2. **Session Drop via App Nap:** When a browser tab or web app window is backgrounded or minimized, macOS throttles the process, causing the `NowPlaying` session to disconnect.
3. **Bloated Workarounds:** Most existing media utilities require invasive **Accessibility permissions**, virtual audio drivers, or heavy Electron background processes that drain battery and sleep cycles.

**MediaKeysFix** solves all of this at the kernel/hardware layer with pure Swift, zero third-party dependencies, and zero permissions needed.

---

## ⚡ Architecture & How It Works

MediaKeysFix uses a high-performance, two-layer interception architecture:

```
[ Physical F7 / F8 / F9 Key Press ]
                │
                ▼
  [ hidutil: Kernel HID Remap ]     ──> Remaps Consumer keys to virtual F16 / F17 / F18
                │
                ▼
  [ MediaKeysFix: Swift App ]       ──> Catches virtual keys via Carbon Event Dispatcher
                │
                ▼
  [ MediaRemote.framework C-API ]   ──> Dispatches command instantly (~2.7ms, 150-200ms debounce)
```

### Key Highlights

* **No Fn Key Interference:** Pressing `Fn + F7`, `Fn + F8`, or `Fn + F9` bypasses remapping completely and sends native functional keys straight to your active terminal, IDE, or game.
* **Auto-Recovery on Sleep/Wake:** macOS can reset HID properties upon system wake or external keyboard re-attachment. MediaKeysFix automatically observes `NSWorkspace.didWakeNotification` and reapplies mappings seamlessly.
* **Emergency Fallback Shortcuts:** Always available global shortcuts in case you are using an external keyboard without dedicated media keys:
  * `Ctrl + Option + Space` — Play / Pause
  * `Ctrl + Option + Left`  — Previous Track
  * `Ctrl + Option + Right` — Next Track
* **Resource Friendly:** Consumes **0.0% CPU** at idle and negligible RAM (~20–40 MB).

---

## 🚀 Installation & Quick Start

### Option 1: Download `.dmg` Installer (Recommended for End-Users)

No terminal or build tools required.

1. Download **[MediaKeysFix.dmg](https://github.com/wavehs/macos-mediakeys-fix/releases/latest)** from the latest GitHub Release.
2. Open the downloaded `.dmg` file.
3. Drag **MediaKeysFix.app** into the **Applications** shortcut in the window.
4. Launch **MediaKeysFix** from your Applications folder or Spotlight:
   * A prompt will ask: *"Enable Start at Login?"* — click **Enable (Recommended)** so media keys work automatically every time you start your Mac.
   * Look for the **⏯ icon in your macOS Menu Bar**!

> [!NOTE]
> Since this is an open-source project without a paid Apple Developer certificate, macOS Gatekeeper may display a warning on the first open. If so, simply right-click (or Control-click) `MediaKeysFix.app` in `/Applications` and select **Open**, then click **Open**.

---

### Option 2: 1-Step Automated Terminal Install

Open Terminal, clone this repository, and run `install.sh`:

```bash
git clone https://github.com/wavehs/macos-mediakeys-fix.git
cd macos-mediakeys-fix
./install.sh
```

The script will automatically compile, package, install to `/Applications`, configure Start at Login, and launch the Menu Bar app.

---

### Option 3: Developer Commands with `make`

```bash
# Package a release-ready .dmg and .zip
make dmg

# Build and install to /Applications with autostart enabled
make install

# Check status of key mapping, launch agents, and running process
make status

# View live execution logs
make logs

# Complete uninstall and revert keyboard to macOS factory defaults
make uninstall
```

---

## 💻 Menu Bar & App Interface

MediaKeysFix sits discreetly in your macOS Menu Bar:

```
[⏯ Menu Bar Icon]
├── MediaKeysFix v1.0.0
├── ● Status: Active
├── ─────────────────────────────────────
├── [✓] Remap F7 / F8 / F9 Keys
├── [✓] Start at Login             <-- One-click auto-startup toggle!
├── [✓] Fallback Shortcuts (⌃⌥Space)
├── ─────────────────────────────────────
├── Quick Media Controls ▶
│   ├── Play / Pause
│   ├── Next Track
│   └── Previous Track
├── ─────────────────────────────────────
├── Re-apply Key Mapping           (⌘R)
├── View Logs...                   (⌘L)
├── ─────────────────────────────────────
├── About MediaKeysFix...
└── Quit MediaKeysFix              (⌘Q)
```

### Start at Login (Auto-startup)

You can toggle **Start at Login** anytime:
* **From the Menu Bar:** Click the ⏯ icon and toggle **Start at Login**.
* **From the Terminal:**
  ```bash
  # Enable autostart on system boot
  /Applications/MediaKeysFix.app/Contents/MacOS/MediaKeysFix --enable-login

  # Disable autostart
  /Applications/MediaKeysFix.app/Contents/MacOS/MediaKeysFix --disable-login
  ```
This manages a clean, standard user LaunchAgent at `~/Library/LaunchAgents/com.user.mediakeysfix.plist`.

---

## ⌨️ Command Line Interface (CLI)

The compiled binary can also be controlled from scripts, Terminal, or automations:

```bash
MediaKeysFix [OPTIONS]

Options:
  --status              Show current status of key mapping and autostart
  --enable-login        Enable Launch at Login (start on computer boot)
  --disable-login       Disable Launch at Login
  --apply-keys          Apply HID key mapping for F7, F8, F9
  --reset-keys          Reset keyboard mappings to macOS default
  --play-pause          Send Play / Pause command
  --next                Send Next Track command
  --prev                Send Previous Track command
  --headless, --daemon  Run in background without menu bar item
  --help, -h            Show help message
```

---

## 🔍 Raycast Integration

Ready-to-use Raycast Script Commands are included under `raycast-scripts/`:

* `play-pause.sh` — Toggle Play / Pause
* `next-track.sh` — Skip to Next Track
* `previous-track.sh` — Go to Previous Track

To install, simply add the `raycast-scripts/` directory to **Raycast Settings → Extensions → Script Commands**.

---

## 📂 Project Structure

```
macos-mediakeys-fix/
├── src/
│   ├── AppDelegate.swift             # App lifecycle and initializers
│   ├── HotKeyManager.swift           # Carbon global hotkeys handler
│   ├── KeyMappingManager.swift       # hidutil kernel key mapping & sleep watcher
│   ├── LaunchAtLoginManager.swift    # LaunchAgent autostart manager
│   ├── MediaRemoteBridge.swift       # Private MediaRemote framework bridge & debounce
│   ├── StatusBarController.swift     # macOS Menu Bar UI and actions
│   ├── Info.plist                    # App bundle metadata
│   └── main.swift                    # CLI router and application entry point
├── resources/
│   └── AppIcon.icns                  # Native macOS Retina application icon
├── scripts/
│   └── generate_icon.swift           # Programmatic AppIcon generator
├── raycast-scripts/                  # Raycast script command integrations
├── install.sh                        # One-command installer script
├── uninstall.sh                      # One-command uninstaller and key reset
├── Makefile                          # Build automation
├── .gitignore
└── README.md
```

---

## 🗑️ Uninstallation

If you ever want to remove MediaKeysFix and return to standard macOS behavior:

```bash
./uninstall.sh
```

Or:

```bash
make uninstall
```

This will:
1. Stop the application.
2. Unload and delete the auto-startup LaunchAgent.
3. Remove the `.app` bundle from `/Applications`.
4. Instantly restore all keyboard mappings back to macOS defaults (`hidutil property --set '{"UserKeyMapping":[]}'`).

---

## ❓ FAQ

#### Does this require Accessibility permissions?
**No.** Unlike Karabiner-Elements or Mac Media Key Forwarder, MediaKeysFix does not intercept your keystrokes using accessibility event taps. It relies on Apple's standard `hidutil` kernel property remapping and Carbon hotkeys, requiring zero permissions.

#### Does this work with Spotify, YouTube Music, Apple Music, and web browsers?
**Yes.** Because it triggers Apple's system `MediaRemote` framework directly, any application that supports macOS NowPlaying (Chrome, Safari, YouTube Music PWA, Spotify, Tidal, Apple Music, VLC) is supported.

#### What happens when my Mac goes to sleep?
macOS sometimes clears `hidutil` tables when entering sleep. MediaKeysFix listens for system wake notifications and automatically restores the keymapping in the background.

#### Can I still use F7, F8, and F9 as function keys in my IDE?
**Yes.** Press `Fn + F7`, `Fn + F8`, or `Fn + F9`. MediaKeysFix only remaps the consumer media actions; holding `Fn` triggers standard function keys.

---

## 📄 License

MIT License. Open source and free to use.

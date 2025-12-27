# Fedora Fresh Install Script

### Bash script that automates setup of a modern Fedora desktop environment.

This script installs applications and tools via **Flatpak**, **DNF (Fedora package manager)**, and **Node.js (NPM)**.  
It also sets up Docker, NVM, GNOME integration, Hyprland configuration, and performs system maintenance.

---

## 🧩 Flatpak Applications (via Flathub)

* **Brave Browser** (`com.brave.Browser`)
* **Spotify** (`com.spotify.Client`)
* **Visual Studio Code** (`com.visualstudio.code`)
* **VLC Media Player** (`org.videolan.VLC`)
* **ZapZap (WhatsApp client)** (`com.rtosta.zapzap`)
* **Steam** (`com.valvesoftware.Steam`)
* **Bottles** (`com.usebottles.bottles`)
* **qBittorrent** (`org.qbittorrent.qBittorrent`)
* **Qalculate** (`io.github.Qalculate`)
* **Pika Backup** (`org.gnome.World.PikaBackup`)

---

## 📦 Fedora Packages (via DNF)

* **Base dependencies:**  
   * `wget`, `curl`, `ca-certificates`, `flatpak`, `dnf-plugins-core`
   * `@development-tools`, `kernel-devel`, `kernel-headers`
   * `rpmfusion-free-release`, `rpmfusion-nonfree-release`

* **GNOME tools** _(if GNOME detected):_  
   * `gnome-tweaks`, `gnome-extensions-app`

* **System utilities:**  
   * `htop`  
   * `tmux`

* **Terminal & Editor:**  
   * `kitty` (terminal emulator)  
   * `neovim` (text editor)

* **Media & Utilities:**  
   * `vlc` (media player)  
   * `qbittorrent` (BitTorrent client)  
   * `qalculate-gtk` (calculator)

* **Gaming:**  
   * `steam` (from RPM Fusion non-free)

* **Docker & Compose:**  
   * `docker-ce`, `docker-ce-cli`, `containerd.io`  
   * `docker-buildx-plugin`, `docker-compose-plugin`

> Docker is fully configured, enabled as a service, and the invoking user is added to the `docker` group.

---

## 🟩 Node.js & Global NPM Packages

The script installs **NVM** (Node Version Manager), **Node.js (LTS and Current)**, and **Corepack** (enabling Yarn & PNPM).  
Global npm packages installed include:

```
axios, react, lodash, chalk, async, colors, eslint, dotenv,
socket.io, react-redux, path, mongodb, bootstrap, less,
sass-loader, postcss, jsonwebtoken, cors, react-router,
browserify, prettier, nodemailer, nodemon, sqlite3
```

---

## 🎨 Hyprland Configuration

The script automatically installs the [Fedora-Hyprland](https://github.com/JaKooLit/Fedora-Hyprland) configuration by cloning the repository and running the installation script. This provides a complete Hyprland window manager setup optimized for Fedora.

---

## ⚙️ Other Features & Tasks

* Updates and upgrades the Fedora system
* Adds **RPM Fusion** repositories (free and non-free)
* Adds **Flathub** if missing
* **Pins** Flatpak apps to the GNOME dock (if GNOME detected)
* Configures **NVM** autoloading in `.bashrc`, `.zshrc`, and `.profile`
* Runs **system maintenance & cleanup**:  
   * `dnf autoremove`  
   * `dnf clean all`  
   * `flatpak update -y`

---

## 🚀 Usage

1. **Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/thijsBoet/linux-install-apps/main/fedora-install-apps.sh
   # Or clone the repository
   git clone https://github.com/thijsBoet/linux-install-apps.git
   cd linux-install-apps
   ```

2. **Make it executable:**
   ```bash
   chmod +x fedora-install-apps.sh
   ```

3. **Run with sudo:**
   ```bash
   sudo bash fedora-install-apps.sh
   ```

> **Important:** Run this script from a native terminal (not a Flatpak/container terminal).  
> The script must be run with `sudo`, not as root directly.

---

## 🚀 After Installation

1. **Reboot or log out/in** for Docker group membership to take effect.
2. **Run pinned app helper (if GNOME):**  
   ```bash
   bash ~/pin-apps-helper.sh
   ```
3. **Verify installations:**  
   ```bash
   docker run hello-world
   docker compose version
   node -v && npm -v
   flatpak run com.brave.Browser
   ```
4. **Launch applications:**
   - **Brave:** `flatpak run com.brave.Browser` (or `brave-browser`)
   - **Spotify:** `flatpak run com.spotify.Client`
   - **VS Code:** `flatpak run com.visualstudio.code` (or `code`)
   - **VLC:** `vlc` (or `flatpak run org.videolan.VLC`)
   - **Steam:** `steam` (or `flatpak run com.valvesoftware.Steam`)
   - **Bottles:** `flatpak run com.usebottles.bottles`
   - **qBittorrent:** `qbittorrent` (or `flatpak run org.qbittorrent.qBittorrent`)
   - **Kitty:** `kitty`
   - **Neovim:** `nvim`
   - **Qalculate:** `qalculate-gtk` (or `flatpak run io.github.Qalculate`)
   - **Pika Backup:** `flatpak run org.gnome.World.PikaBackup`
5. **For NVM/Node.js in new terminals:**
   ```bash
   source ~/.bashrc
   ```
6. **Steam:** First launch will download additional components.
7. **Enjoy your new Fedora setup!**

---

## 📋 Requirements

* Fresh Fedora 42 installation (or compatible version)
* Internet connection
* Root/sudo access
* Native terminal (not Flatpak/container)

---

## 🔧 Troubleshooting

* **"no new privileges" error:** You're running in a Flatpak/container terminal. Use a native terminal instead.
* **Docker group not working:** Log out and log back in (or reboot) after installation.
* **Flatpak apps not showing:** Ensure Flathub is enabled: `flatpak remote-list`
* **RPM Fusion packages not found:** The script automatically installs RPM Fusion repos, but if issues persist, manually install: `sudo dnf install rpmfusion-free-release rpmfusion-nonfree-release`

---

## 📜 Script Location

The script is available at:  
**https://github.com/thijsBoet/linux-install-apps/blob/main/fedora-install-apps.sh**

---

**Repository:** [thijsBoet/linux-install-apps](https://github.com/thijsBoet/linux-install-apps)  
**Author:** Automated Setup Script for Fedora  
**License:** GPL


# CentOS / RHEL Fresh Install Script

### Bash script that automates setup of a modern CentOS desktop environment.

This script installs applications and tools via **Flatpak**, **DNF (CentOS package manager)**, and **Node.js (NPM)**.  
It also sets up Docker, NVM, GNOME integration, and performs system maintenance.

---

## 🧩 Flatpak Applications (via Flathub)
- **Google Chrome** (`com.google.Chrome`)
- **Spotify** (`com.spotify.Client`)
- **Visual Studio Code** (`com.visualstudio.code`)
- **VLC Media Player** (`org.videolan.VLC`)
- **ZapZap (WhatsApp client)** (`com.rtosta.zapzap`)

---

## 📦 CentOS Packages (via DNF)
- **wget**, **curl**, **gnupg**, **ca-certificates**, **flatpak**
- **make**, **gcc**, **gcc-c++**, **kernel-devel**, **elfutils-libelf-devel**
- **epel-release**
- **gnome-shell-extension-prefs**, **gnome-tweaks** *(if GNOME detected)*
- **System utilities:**
  - `htop`
  - `tmux`
  - `timeshift`
- **Docker & Compose:**
  - `docker-ce`, `docker-ce-cli`, `containerd.io`
  - `docker-buildx-plugin`, `docker-compose-plugin`

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

## ⚙️ Other Features & Tasks

- Adds **Flathub** if missing
- **Pins** Flatpak apps to the GNOME dock
- Configures **NVM** autoloading in `.bashrc`, `.zshrc`, and `.profile`
- Runs **system maintenance & cleanup**:
  - `dnf autoremove`
  - `dnf clean all`
  - `flatpak update -y`

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
   node -v && npm -v
   flatpak run com.google.Chrome
   ```
4. **Enjoy your new CentOS setup!**

---

## 📜 Full Installation Script

Below is the complete script for reference:

```bash
{script_content}
```

---

**Author:** Automated Setup Script for CentOS/RHEL  
**License:** GPL  

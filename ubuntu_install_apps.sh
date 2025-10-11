#!/bin/bash
set -euo pipefail
# This script must be run from a NATIVE terminal (not Flatpak terminal)
# If you get "no new privileges" error, you're in a Flatpak/container terminal

echo "=== Ubuntu/Debian App Installation Script ==="
echo ""

# Check if we're in a container/flatpak (which causes the sudo issue)
if [ -f /.dockerenv ] || [ -f /run/.containerenv ] || grep -q flatpak /proc/1/cgroup 2>/dev/null; then
    echo "ERROR: This script is running inside a container or Flatpak!"
    echo "Please run this script from your native system terminal:"
    echo "  1. Exit this terminal"
    echo "  2. Press Ctrl+Alt+T or open 'Terminal' from applications"
    echo "  3. Navigate to script location and run: sudo bash $0"
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs root privileges."
    echo "Please run: sudo bash $0"
    exit 1
fi

# Determine the real desktop user (the one who invoked sudo)
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
else
    echo "Error: Could not determine target user. Please run with sudo, not as root directly."
    exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_UID="$(id -u "$TARGET_USER")"
TARGET_GID="$(id -g "$TARGET_USER")"

echo "Target user: $TARGET_USER ($TARGET_HOME)"
echo "Target UID/GID: $TARGET_UID/$TARGET_GID"
echo ""

echo "=== Updating Ubuntu/Debian ==="
apt update
apt -y upgrade

echo "=== Installing Required Dependencies ==="
apt -y install wget curl gnupg ca-certificates flatpak \
    build-essential linux-headers-$(uname -r) software-properties-common \
    apt-transport-https

# Install GNOME tools only if GNOME is available
if dpkg -l | grep -q gnome-shell; then
    apt -y install gnome-shell-extension-prefs gnome-tweaks || true
fi

# Ensure Flathub is enabled for Flatpak
if ! flatpak remote-list | grep -q flathub; then
    echo "=== Adding Flathub repository ==="
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

#############################################
# Google Chrome (from APT if possible, otherwise Flatpak)
#############################################
echo "=== Installing Google Chrome ==="
# Check if Chrome repo is already configured
if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
    apt update
fi
apt -y install google-chrome-stable || {
    echo "APT install failed, falling back to Flatpak..."
    flatpak install -y flathub com.google.Chrome
}

#############################################
# Spotify (from APT if possible, otherwise Flatpak)
#############################################
echo "=== Installing Spotify ==="
if [ ! -f /etc/apt/sources.list.d/spotify.list ]; then
    curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | gpg --dearmor -o /usr/share/keyrings/spotify-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/spotify-keyring.gpg] http://repository.spotify.com stable non-free" > /etc/apt/sources.list.d/spotify.list
    apt update
fi
apt -y install spotify-client || {
    echo "APT install failed, falling back to Flatpak..."
    flatpak install -y flathub com.spotify.Client
}

#############################################
# Visual Studio Code (from APT)
#############################################
echo "=== Installing VS Code ==="
if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-keyring.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
    apt update
fi
apt -y install code || {
    echo "APT install failed, falling back to Flatpak..."
    flatpak install -y flathub com.visualstudio.code
}

#############################################
# VLC (from APT)
#############################################
echo "=== Installing VLC ==="
apt -y install vlc || {
    echo "APT install failed, falling back to Flatpak..."
    flatpak install -y flathub org.videolan.VLC
}

#############################################
# ZapZap (Flatpak)
#############################################
echo "=== Installing ZapZap ==="
flatpak install -y flathub com.rtosta.zapzap

#############################################
# Install System Tools (APT)
#############################################
echo "=== Installing System Tools ==="
apt -y install \
    htop \
    tmux \
    timeshift

#############################################
# Docker
#############################################
echo "=== Installing Docker ==="
# Remove old versions if present
apt remove -y docker \
    docker-engine \
    docker.io \
    containerd \
    runc || true

# Install Docker repository
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Detect Ubuntu/Debian and set appropriate repository
if [ -f /etc/debian_version ]; then
    if [ -f /etc/lsb-release ]; then
        # Ubuntu
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
    else
        # Debian
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
    fi
fi

apt update
apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add target user to docker group
usermod -aG docker "$TARGET_USER"

echo "Docker installed successfully. User $TARGET_USER added to docker group."
echo "Note: User needs to log out and back in for docker group to take effect."

#############################################
# VirtualBox (optional)
#############################################
# echo "=== Installing VirtualBox ==="
# wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | gpg --dearmor -o /usr/share/keyrings/oracle-virtualbox-2016.gpg
# echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" > /etc/apt/sources.list.d/virtualbox.list
# apt update
# apt -y install virtualbox-7.0

#############################################
# nvm + Node.js (Latest nvm + Latest LTS and Current)
#############################################
echo "=== Installing NVM for $TARGET_USER ==="
runuser -u "$TARGET_USER" -- bash -c '
  set -e
  export NVM_DIR="$HOME/.nvm"
  if [ ! -d "$NVM_DIR" ]; then
    echo "Downloading and running nvm installer (latest stable)..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
  else
    echo "NVM already present at $NVM_DIR"
  fi
  
  # Ensure nvm is available in this non-login shell
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  
  echo "Installing Node.js Latest LTS..."
  nvm install --lts
  
  echo "Installing Node.js Latest Current..."
  nvm install node
  
  echo "Setting default Node.js to LTS..."
  nvm alias default lts/*
  
  echo "Enabling Corepack (Yarn/PNPM shims)..."
  corepack enable || true
  
  echo "Node versions installed:"
  nvm ls
  node -v
  npm -v
'

# Make sure user shells always load nvm (idempotent)
echo "=== Wiring NVM into $TARGET_USER shell profiles ==="
NVM_SNIPPET='export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"'

for RC in ".bashrc" ".zshrc" ".profile"; do
  RC_PATH="$TARGET_HOME/$RC"
  if [ -f "$RC_PATH" ]; then
    if ! grep -q 'export NVM_DIR="$HOME/.nvm"' "$RC_PATH"; then
      echo "$NVM_SNIPPET" >> "$RC_PATH"
    fi
  else
    echo "$NVM_SNIPPET" > "$RC_PATH"
    chown "$TARGET_USER":"$TARGET_USER" "$RC_PATH"
  fi
done

#############################################
# Install global NPM packages (as TARGET_USER)
#############################################
echo "=== Installing global NPM packages ==="
runuser -u "$TARGET_USER" -- bash -c '
  set -e
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  
  npm install -g \
    axios \
    react \
    lodash \
    chalk \
    async \
    colors \
    eslint \
    dotenv \
    socket.io \
    react-redux \
    path \
    mongodb \
    bootstrap \
    less \
    sass-loader \
    postcss \
    jsonwebtoken \
    cors \
    react-router \
    browserify \
    prettier \
    nodemailer \
    nodemon \
    sqlite3
'

#############################################
# Pin Apps to Dock (GNOME only)
#############################################
if command -v gnome-shell &> /dev/null; then
    echo "=== Creating dock pinning helper ==="
    
    # Create a helper script for the user to run
    HELPER_SCRIPT="$TARGET_HOME/pin-apps-helper.sh"
    cat > "$HELPER_SCRIPT" <<'EOFHELPER'
#!/bin/bash
CURRENT_FAVORITES=$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "[]")
FAVORITES=$(echo "$CURRENT_FAVORITES" | sed "s/^\['//;s/'\]$//;s/', '/ /g")

NEW_APPS=(
    "google-chrome.desktop"
    "spotify.desktop"
    "code.desktop"
    "vlc.desktop"
    "com.rtosta.zapzap.desktop"
)

for APP in "${NEW_APPS[@]}"; do
    if [[ ! " $FAVORITES " =~ " $APP " ]]; then
        FAVORITES="$FAVORITES $APP"
    fi
done

UPDATED_FAVORITES=$(printf "'%s', " $FAVORITES)
UPDATED_FAVORITES="[${UPDATED_FAVORITES%, }]"

gsettings set org.gnome.shell favorite-apps "$UPDATED_FAVORITES" 2>/dev/null && \
    echo "Apps pinned successfully!" || \
    echo "Warning: Could not pin apps automatically."

rm -f "$0"
EOFHELPER
    chown "$TARGET_USER":"$TARGET_USER" "$HELPER_SCRIPT"
    chmod +x "$HELPER_SCRIPT"
    
    echo "Created helper script at $HELPER_SCRIPT"
else
    echo "=== GNOME Shell not detected, skipping dock pinning ==="
fi

#############################################
# Maintenance & Cleanup
#############################################
echo "=== Running Maintenance & Cleanup ==="
apt -y autoremove
apt clean
flatpak update -y || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                   All Done! 🚀                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. 🔄 RESTART your session (log out and log back in)"
echo "   - Required for docker group membership to take effect"
echo ""
echo "2. 📱 Launch apps from Activities or run:"
echo "   - Chrome:   google-chrome (or flatpak run com.google.Chrome)"
echo "   - Spotify:  spotify (or flatpak run com.spotify.Client)"
echo "   - VS Code:  code (or flatpak run com.visualstudio.code)"
echo "   - VLC:      vlc (or flatpak run org.videolan.VLC)"
echo "   - ZapZap:   flatpak run com.rtosta.zapzap"
echo ""
echo "3. 📌 To pin apps to your dock, run as $TARGET_USER:"
if [ -f "$TARGET_HOME/pin-apps-helper.sh" ]; then
    echo "   bash ~/pin-apps-helper.sh"
fi
echo ""
echo "4. 💻 For NVM/Node.js in new terminals:"
echo "   source ~/.bashrc"
echo ""
echo "5. 🐳 Test Docker (after relogging):"
echo "   docker run hello-world"
echo "   docker compose version"
echo ""
echo "Enjoy your new setup! 🎉"
echo ""

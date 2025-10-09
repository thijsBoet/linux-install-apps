#!/bin/bash
set -euo pipefail

# This script must be run from a NATIVE terminal (not Flatpak terminal)
# If you get "no new privileges" error, you're in a Flatpak/container terminal

echo "=== CentOS App Installation Script ==="
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

echo "=== Updating CentOS/RHEL ==="
dnf -y update

echo "=== Installing Required Dependencies ==="
dnf -y install wget curl gnupg ca-certificates flatpak \
    make gcc gcc-c++ kernel-devel elfutils-libelf-devel

# Install GNOME tools only if GNOME is available
if rpm -q gnome-shell &>/dev/null; then
    dnf -y install gnome-shell-extension-prefs gnome-tweaks || true
fi

# Enable EPEL repository (Extra Packages for Enterprise Linux)
dnf -y install epel-release

# Ensure Flathub is enabled for Flatpak
if ! flatpak remote-list | grep -q flathub; then
    echo "=== Adding Flathub repository ==="
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

#############################################
# Google Chrome (Flatpak preferred)
#############################################
echo "=== Installing Google Chrome via Flatpak ==="
flatpak install -y flathub com.google.Chrome

#############################################
# Spotify (Flatpak preferred)
#############################################
echo "=== Installing Spotify via Flatpak ==="
flatpak install -y flathub com.spotify.Client

#############################################
# Visual Studio Code (Flatpak preferred)
#############################################
echo "=== Installing VS Code via Flatpak ==="
flatpak install -y flathub com.visualstudio.code

#############################################
# VLC (Flatpak preferred)
#############################################
echo "=== Installing VLC via Flatpak ==="
flatpak install -y flathub org.videolan.VLC

#############################################
# ZapZap (Flatpak)
#############################################
echo "=== Installing ZapZap ==="
flatpak install -y flathub com.rtosta.zapzap

#############################################
# Install System Tools (DNF)
#############################################
echo "=== Installing System Tools ==="
dnf -y install \
    htop \
    tmux \
    timeshift

#############################################
# Docker
#############################################
echo "=== Installing Docker ==="
# Remove old versions if present
dnf remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine \
    podman \
    runc || true

# Install Docker CE repository
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add target user to docker group
usermod -aG docker "$TARGET_USER"

echo "Docker installed successfully. User $TARGET_USER added to docker group."
echo "Note: User needs to log out and back in for docker group to take effect."

#############################################
# VirtualBox (optional - commented out due to complexity)
#############################################
# Note: VirtualBox on CentOS/RHEL requires specific kernel versions
# and is more complex. Uncomment if needed and verify compatibility.
# echo "=== Installing VirtualBox ==="
# dnf config-manager --add-repo=https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo
# dnf -y install VirtualBox-7.0

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
    "com.google.Chrome.desktop"
    "com.spotify.Client.desktop"
    "com.visualstudio.code.desktop"
    "com.rtosta.zapzap.desktop"
    "org.videolan.VLC.desktop"
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
dnf -y autoremove
dnf clean all
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
echo "   - Chrome:   flatpak run com.google.Chrome"
echo "   - Spotify:  flatpak run com.spotify.Client"
echo "   - VS Code:  flatpak run com.visualstudio.code"
echo "   - VLC:      flatpak run org.videolan.VLC"
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
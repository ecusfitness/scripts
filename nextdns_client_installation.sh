#!/usr/bin/env bash
set -e

# ==============================
# CONFIG
# ==============================
NEXTDNS_PROFILE_ID="f9981c"

# ==============================
# FUNCTIONS
# ==============================
info() {
  echo "▶ $1"
}

error() {
  echo "✖ $1" >&2
  exit 1
}

# ==============================
# CHECK macOS
# ==============================
if [[ "$(uname)" != "Darwin" ]]; then
  error "This script is intended for macOS only."
fi

# ==============================
# INSTALL NEXTDNS
# ==============================
if ! command -v nextdns >/dev/null 2>&1; then
  info "Installing NextDNS CLI..."
  curl -fsSL https://nextdns.io/install | bash
else
  info "NextDNS CLI already installed."
fi

# ==============================
# INSTALL & START SERVICE
# ==============================
info "Installing NextDNS service (launchd)..."
sudo nextdns install || true

# ==============================
# CONFIGURE PROFILE
# ==============================
info "Configuring NextDNS with profile ID: $NEXTDNS_PROFILE_ID"
sudo nextdns config set profile "$NEXTDNS_PROFILE_ID"

# Optional hardening / strict mode
info "Applying strict settings..."
sudo nextdns config set auto-activate true
sudo nextdns config set cache-size 10MB
sudo nextdns config set report-client-info true

# ==============================
# RESTART SERVICE
# ==============================
info "Restarting NextDNS service..."
sudo nextdns restart

# ==============================
# STATUS CHECK
# ==============================
info "NextDNS status:"
nextdns status

echo "✔ NextDNS installation and configuration completed successfully."

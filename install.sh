#!/usr/bin/env bash
# install.sh - Third-party contract entry point for iDempiere
#
# Self-contained installer that wraps existing installation steps.
# Executes three phases: prerequisites → ansible → service
#
# Usage: ./install.sh
#
# Assumes:
#   - NixOS base system
#   - Script directory contains idempiere-prerequisites.nix, idempiere-service.nix, ansible/

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== iDempiere Installation ==="
echo "Script directory: $SCRIPT_DIR"

# Phase 1: NixOS Prerequisites
echo ""
echo "=== Phase 1: NixOS Prerequisites ==="
if grep -q "idempiere-prerequisites.nix" /etc/nixos/configuration.nix; then
    echo "Prerequisites already in configuration.nix, skipping..."
else
    sed -i 's|./incus.nix|./incus.nix\n    '"$SCRIPT_DIR"'/idempiere-prerequisites.nix|' /etc/nixos/configuration.nix
fi
sudo nixos-rebuild switch

# Phase 2: Ansible Installation
echo ""
echo "=== Phase 2: Ansible Installation ==="
cd "$SCRIPT_DIR/ansible"
ansible-playbook -i inventory.ini idempiere-install.yml -e 'import_database=true' --connection=local

# Phase 3: NixOS Service
echo ""
echo "=== Phase 3: NixOS Service ==="
if grep -q "idempiere-service.nix" /etc/nixos/configuration.nix; then
    echo "Service already in configuration.nix, skipping..."
else
    sed -i 's|idempiere-prerequisites.nix|idempiere-prerequisites.nix\n    '"$SCRIPT_DIR"'/idempiere-service.nix|' /etc/nixos/configuration.nix
fi
sudo nixos-rebuild switch

echo ""
echo "=== iDempiere Installation Complete ==="
echo "Service status: systemctl status idempiere"
echo "Web UI: http://localhost:8080/webui/"
echo "REST API: http://localhost:8080/api/v1/"

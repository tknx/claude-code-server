#!/bin/bash
set -e

# ── SSH Server ─────────────────────────────────────────────────────────────────
# Generate host keys if they don't exist (persisted via volume so they survive
# container rebuilds — avoids "remote host identification changed" warnings)
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "[entrypoint] Generating SSH host keys..."
    ssh-keygen -A
fi

echo "[entrypoint] Starting SSH server..."
/usr/sbin/sshd

# ── Git Config ─────────────────────────────────────────────────────────────────
# Set safe directory so git works on volume-mounted repos owned by host user
git config --global --add safe.directory '*'

# ── Optional: pull latest Loxone repo on startup ──────────────────────────────
if [ -d /projects/loxone/.git ]; then
    echo "[entrypoint] Pulling latest Loxone repo..."
    git -C /projects/loxone pull --ff-only 2>/dev/null || echo "[entrypoint] Git pull skipped (dirty or no remote)"
fi

# ── Claude Code Remote Control ─────────────────────────────────────────────────
echo "[entrypoint] Starting Claude Code in remote-control mode..."
echo "[entrypoint] Connect at claude.ai/code or via SSH to this container"
echo ""

# exec replaces this shell as PID 1 so Docker signals (stop/restart) work correctly.
# --dangerously-skip-permissions avoids interactive approval prompts in the container
# since you'll be approving via the remote control UI on your phone/browser instead.
exec claude remote-control --dangerously-skip-permissions

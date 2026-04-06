#!/bin/bash
set -e

# ── SSH Server ─────────────────────────────────────────────────────────────────
# Generate host keys if they don't exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "[entrypoint] Generating SSH host keys..."
    ssh-keygen -A
fi

echo "[entrypoint] Starting SSH server..."
/usr/sbin/sshd

# ── Git Config ─────────────────────────────────────────────────────────────────
git config --global --add safe.directory '*'

# ── Optional: pull latest Loxone repo on startup ──────────────────────────────
if [ -d /mnt/user/projects/loxone/.git ]; then
    echo "[entrypoint] Pulling latest Loxone repo..."
    git -C /mnt/user/projects/loxone pull --ff-only 2>/dev/null || echo "[entrypoint] Git pull skipped (dirty or no remote)"
fi

# ── Wait for login before starting remote-control ─────────────────────────────
# On first boot, SSH in and run: claude /login
# Once authenticated, run: claude remote-control --dangerously-skip-permissions
# The container will stay up via sshd until you're ready.
if [ -f /root/.claude/credentials.json ]; then
    echo "[entrypoint] Credentials found, starting Claude Code in remote-control mode..."
    echo "[entrypoint] Connect at claude.ai/code or via SSH to this container"
    exec claude remote-control --dangerously-skip-permissions
else
    echo "[entrypoint] No credentials found."
    echo "[entrypoint] SSH in and run: claude /login"
    echo "[entrypoint] Then restart the container to launch remote-control automatically."
    exec /usr/sbin/sshd -D
fi

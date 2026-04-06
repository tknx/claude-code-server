# Claude Code Server

Persistent Docker container running Claude Code with:
- **Remote Control** on startup → control from claude.ai/code or Claude mobile app
- **SSH server** → terminal access via `ssh -p 2222 root@tower`

## First-Time Setup

### 1. Create appdata directories on Tower

```bash
mkdir -p /mnt/user/appdata/claude-code/{ssh/host-keys,projects,claude-config}
```

### 2. Copy your Claude auth from your Mac

Remote Control requires a Pro/Max account (not just an API key).
Copy the credentials from your Mac Studio:

```bash
# On your Mac:
scp ~/.config/claude/credentials.json tower:/mnt/user/appdata/claude-code/auth.json
```

> If the file is at `~/.config/claude-code/auth.json` on older versions, use that path instead.

### 3. Set up SSH authorized_keys

```bash
# Copy your Mac's public key so you can SSH into the container
cat ~/.ssh/id_ed25519.pub | ssh tower "cat >> /mnt/user/appdata/claude-code/ssh/authorized_keys"
chmod 600 /mnt/user/appdata/claude-code/ssh/authorized_keys
```

### 4. Copy your rclone config (if using rclone for Windows VM sync)

```bash
scp ~/.config/rclone/rclone.conf tower:/mnt/user/appdata/claude-code/rclone.conf
```

### 5. Set ANTHROPIC_API_KEY in Unraid

In Unraid → Settings → Docker → (container env vars), or use a `.env` file alongside docker-compose.yml:

```bash
echo "ANTHROPIC_API_KEY=sk-ant-..." > /mnt/user/appdata/claude-code/.env
```

### 6. Clone your Loxone repo into projects

```bash
ssh tower
git clone git@github.com:tknx/loxone.git /mnt/user/appdata/claude-code/projects/loxone
```

### 7. Build and start

```bash
docker compose up -d --build
```

---

## Daily Usage

### Remote Control (default)
Container starts and immediately registers a remote-control session.
Open **claude.ai/code** or the Claude mobile app → look for the session with a green dot.

### SSH Terminal Access
```bash
ssh -p 2222 root@10.0.0.101
# or via Tailscale from anywhere:
ssh -p 2222 root@tower
```

Once inside, you can:
```bash
cd /projects/loxone
claude                    # start interactive Claude Code session
# then /rc inside Claude to start remote-control from within
```

### Sync Loxone files from Windows VM

Add an rclone remote called `loxone-vm` pointing at the Windows VM SMB share:
```bash
rclone sync loxone-vm:/LoxoneConfig /projects/loxone/configs/
```

Or via SSH if the VM has OpenSSH:
```bash
rclone sync :sftp,host=10.0.0.xxx,user=tarun:/LoxoneConfig /projects/loxone/configs/
```

### SSH to DietPi for VictoriaMetrics logs

```bash
ssh tarun@10.0.0.201 "journalctl -u victoriametrics -n 100"
```

Pre-add DietPi to known_hosts so Claude can do this non-interactively:
```bash
ssh-keyscan 10.0.0.201 >> /mnt/user/appdata/claude-code/ssh/known_hosts
```

---

## CLAUDE.md (project memory)

Create `/mnt/user/appdata/claude-code/projects/loxone/CLAUDE.md` with context
Claude Code will load automatically on every session:

```markdown
# Loxone Project

- Master Miniserver Gen2: 10.0.20.11
- Slave Miniserver Gen1: 10.0.20.12
- Always read XML files directly, do not interpret screenshots
- Consult official Loxone documentation before advising on block behavior
- XML files are in /projects/loxone/configs/
```

---

## Troubleshooting

**Remote control not appearing in app:**
- Confirm you're on Pro or Max plan (API keys don't work for remote-control)
- Check container logs: `docker logs claude-code`
- Auth file may need refreshing: re-copy from Mac

**SSH connection refused:**
- Check authorized_keys permissions: must be 600
- Verify port 2222 isn't blocked by Unraid firewall

**New session ID on every restart:**
- Known upstream limitation (GitHub issue #29748)
- Old sessions appear as disconnected in the app, just dismiss them

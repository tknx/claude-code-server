FROM node:22-bookworm-slim

# Install system dependencies
# Note: cifs-utils and nfs-common are intentionally excluded — mounting SMB/NFS
# inside a container requires --privileged which is unacceptable for an LLM agent
# on a homelab host. Instead, mount shares via Unraid's Unassigned Devices plugin
# and bind-mount the resulting path (e.g. /mnt/disks/WindowsVM) into the container.
RUN apt-get update && apt-get install -y \
    # SSH server + client
    openssh-server \
    openssh-client \
    # Git
    git \
    # rclone for user-space file sync (SMB, SFTP, etc. — no kernel mounts needed)
    rclone \
    # smbclient for user-space SMB access without mounting
    smbclient \
    # Useful CLI tools Claude Code leverages
    curl \
    wget \
    jq \
    ripgrep \
    less \
    procps \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# --- SSH Server Setup ---
RUN mkdir /var/run/sshd

# Harden SSH: key auth only, no password auth, no root password login
RUN sed -i \
    -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' \
    -e 's/PasswordAuthentication yes/PasswordAuthentication no/' \
    -e 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' \
    /etc/ssh/sshd_config

# Allow SSH to work without a TTY allocation issue in Docker
RUN echo "PrintMotd no" >> /etc/ssh/sshd_config

# --- Directory Setup ---
RUN mkdir -p \
    /root/.ssh \
    /root/.config/claude \
    /root/.config/rclone \
    /projects

# SSH key perms
RUN chmod 700 /root/.ssh

# --- Entrypoint ---
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]

#!/bin/bash


# This is the safe, recommended way to grant passwordless sudo to specific commands or users.

# Here's how you can do it safely:

# Step 1: Create a new file in /etc/sudoers.d/

# For example, name it yride-systemctl:

# sudo visudo -f /etc/sudoers.d/yride-systemctl

# Step 2: Add this line
# yride ALL=(ALL) NOPASSWD: /bin/systemctl


# This allows the yride user to run only systemctl commands via sudo without a password.

# It does not give full passwordless root access.

# The path /bin/systemctl must match your system (use which systemctl to verify).

# Step 3: Save and exit

# visudo will check for syntax errors. If OK, it saves the file safely.

# Step 4: Test it
# ssh yride@$JETSON_STATIC_IP "sudo systemctl status ptp4l.service"


# It should not prompt for a password.

# ✅ Benefits

# Safe: the original /etc/sudoers is untouched.

# Scoped: only allows systemctl, not arbitrary commands.

# Works with scripts and SSH: you no longer need -t for sudo prompts.

restart_computer_ptp() {

    echo "Restarting systemctl daemon, ptp4l, phc2sys, phc2shm, and chrony"
    sudo systemctl daemon-reload
    sudo systemctl restart ptp4l phc2sys phc2shm chrony
    return 0
}
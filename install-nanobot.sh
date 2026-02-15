#!/bin/sh
set -e

# Detect package manager more robustly - check what's actually managing packages
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        arch|manjaro)
            PKG_INSTALL_CMD="pacman -S --noconfirm"
            BUILD_DEPS="base-devel openssl zlib bzip2 xz tk sqlite libffi"
            EXTRA_UTILS="curl fish go rust"
            ;;
        ubuntu|debian|pop|mint)
            PKG_INSTALL_CMD="apt-get install -y"
            BUILD_DEPS="build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libffi-dev liblzma-dev tk-dev"
            EXTRA_UTILS="curl fish golang rustc"
            ;;
        fedora|rhel|rocky|almalinux|centos)
            PKG_INSTALL_CMD="dnf install -y"
            BUILD_DEPS="gcc gcc-c++ make openssl-devel zlib-devel bzip2-devel readline-devel sqlite-devel libffi-devel xz-devel tk-devel"
            EXTRA_UTILS="curl fish golang rust cargo"
            ;;
        opensuse*|sles)
            PKG_INSTALL_CMD="zypper install -y"
            BUILD_DEPS="gcc gcc-c++ make libopenssl-devel zlib-devel libbz2-devel readline-devel sqlite3-devel libffi-devel xz-devel tk-devel"
            EXTRA_UTILS="curl fish go rust"
            ;;
        *)
            echo "Error: Unsupported distribution: $ID"
            exit 1
            ;;
    esac
else
    echo "Error: Cannot detect distribution (/etc/os-release not found)"
    exit 1
fi

echo '  _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____
 |_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|


 _   _    _    _   _  ___  ____   ___ _____
| \ | |  / \  | \ | |/ _ \| __ ) / _ \_   _|
|  \| | / _ \ |  \| | | | |  _ \| | | || |
| |\  |/ ___ \| |\  | |_| | |_) | |_| || |
|_| \_/_/   \_\_| \_|\___/|____/ \___/ |_|

 ___ _   _ ____ _____  _    _     _       ____   ____ ____  ___ ____ _____
|_ _| \ | / ___|_   _|/ \  | |   | |     / ___| / ___|  _ \|_ _|  _ \_   _|
 | ||  \| \___ \ | | / _ \ | |   | |     \___ \| |   | |_) || || |_) || |
 | || |\  |___) || |/ ___ \| |___| |___   ___) | |___|  _ < | ||  __/ | |
|___|_| \_|____/ |_/_/   \_\_____|_____| |____/ \____|_| \_\___|_|    |_|



 _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ _____
|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|'

echo ""
echo "This script installs nanobot for you. Dependencies:"
echo "    - Modern linux/posix-compatible system"
echo "    - curl"
echo "    - SystemD"
echo "    - Either pacman/apt-get/dnf/zypper"
echo "    - /tmp dir"
echo "    This install script also takes 15 mins - 2 hours depending on system."
echo "    (As we need to compile the right version of python from source)"
echo "    This install script needs to be run as root."
echo ""
echo "    [1] I agree"
echo "    [2] I disagree"
echo ""
printf "Enter choice: "
read -r user_choice

if [ "$user_choice" = "2" ]; then
    echo "Installation cancelled."
    exit 0
fi

echo ' ____  _               _
/ ___|| |_ ___ _ __   / |
\___ \| __/ _ \ '"'"'_ \  | |  _____
 ___) | ||  __/ |_) | | | |_____|
|____/ \__\___| .__/  |_|
              |_|
 ____                                 _   _
|  _ \ _ __ ___ _ __   __ _ _ __ __ _| |_(_) ___  _ __
| |_) | '"'"'__/ _ \ '"'"'_ \ / _` | '"'"'__/ _` | __| |/ _ \| '"'"'_ \
|  __/| | |  __/ |_) | (_| | | | (_| | |_| | (_) | | | |
|_|   |_|  \___| .__/ \__,_|_|  \__,_|\__|_|\___/|_| |_|
               |_|                                      '

echo "Installing base dependencies..."
$PKG_INSTALL_CMD make wget git nano $BUILD_DEPS

echo ""
echo "Would you like to make life easier for your ai agent by installing some extra system utilities?"
echo ""
echo "[1] Yes"
echo "[2] No"
echo ""
printf "Enter choice: "
read -r extra_utils

if [ "$extra_utils" = "1" ]; then
    echo "Installing extra utilities..."
    $PKG_INSTALL_CMD $EXTRA_UTILS
fi

cd /tmp
mkdir -p nanobot-install-script
cd nanobot-install-script
mkdir -p python
cd python
wget 'https://www.python.org/ftp/python/3.12.12/Python-3.12.12.tgz'
tar -xzf 'Python-3.12.12.tgz'
cd 'Python-3.12.12'
./configure --enable-optimizations
make altinstall

mkdir -p /opt/nanobot
cd /opt/nanobot
/usr/local/bin/python3.12 -m venv venv
. venv/bin/activate

tee /opt/nanobot/run.sh << 'EOF'
#!/bin/sh
cd /opt/nanobot
. venv/bin/activate
nanobot gateway
EOF
chmod +x /opt/nanobot/run.sh

cd /tmp
echo ' ____  _               ____
/ ___|| |_ ___ _ __   |___ \
\___ \| __/ _ \ '"'"'_ \    __) |  _____
 ___) | ||  __/ |_) |  / __/  |_____|
|____/ \__\___| .__/  |_____|
              |_|
 _   _                   _           _     ___           _        _ _
| \ | | __ _ _ __   ___ | |__   ___ | |_  |_ _|_ __  ___| |_ __ _| | |
|  \| |/ _'"'"` | '"'"'_ \ / _ \| '"'"'_ \ / _ \| __|  | || '"'"'_ \/ __| __/ _` | | |
| |\  | (_| | | | | (_) | |_) | (_) | |_   | || | | \__ \ || (_| | | |
|_| \_|\__,_|_| |_|\___/|_.__/ \___/ \__| |___|_| |_|___/\__\__,_|_|_|'

git clone https://github.com/HKUDS/nanobot
cd nanobot
/opt/nanobot/venv/bin/pip install -e .
/opt/nanobot/venv/bin/nanobot onboard

echo ""
echo "You'll now be editing the config.json to set your api provider and integrations."
echo "For more info, go to https://github.com/HKUDS/nanobot."
sleep 1
echo '4'
sleep 1
echo '3'
sleep 1
echo '2'
sleep 1
echo '1'
sleep 1
echo '0'

groupadd -r nanobot || true
useradd -r -g nanobot -s /bin/bash -m nanobot || true
chown -R nanobot:nanobot /opt/nanobot

echo ""
echo "Dropping you into nanobot user shell to configure and test."
echo "Edit config with: nano ~/.nanobot/config.json"
echo "Test with: nanobot agent -m 'Hey nanobot, what are the first 20 powers of 2?'"
echo "Type 'exit' when done."
echo ""
sudo -u nanobot -i

echo ' ____  _               _____
/ ___|| |_ ___ _ __   |___ /
\___ \| __/ _ \ '"'"'_ \    |_ \   _____
 ___) | ||  __/ |_) |  ___) | |_____|
|____/ \__\___| .__/  |____/
              |_|
 ____            _                     _   _   _       _ _
/ ___| _   _ ___| |_ ___ _ __ ___   __| | | | | |_ __ (_) |_
\___ \| | | / __| __/ _ \ '"'"'_ ` _ \ / _` | | | | | '"'"'_ \| | __|
 ___) | |_| \__ \ ||  __/ | | | | | (_| | | |_| | | | | | |_
|____/ \__, |___/\__\___|_| |_| |_|\__,_|  \___/|_| |_|_|\__|
       |___/               '

tee /etc/systemd/system/nanobot.service << 'EOF'
[Unit]
Description=Nanobot Service
After=network.target

[Service]
Type=simple
User=nanobot
Group=nanobot
WorkingDirectory=/opt/nanobot
ExecStart=/bin/sh /opt/nanobot/run.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security (optional):
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/opt/nanobot

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "SystemD service created at /etc/systemd/system/nanobot.service"
echo ""
echo "Run to enable nanobot on boot:"
echo "    systemctl daemon-reload"
echo "    systemctl enable nanobot --now"
echo ""
echo "Nanobot will run now and on subsequent boots after running these commands."

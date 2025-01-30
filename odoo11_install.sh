#!/bin/bash

# Define variables
projname="mrV11"
python_version="python3.6"
db_port=5433
db_password="digipg@dm1n"
xmlrpc_port=1334
postgresql="postgresql-9.6"

# Update system packages
sudo apt update && sudo apt-get dist-upgrade -y

# Ensure the user and group for the project exist
if ! id -u $projname >/dev/null 2>&1; then
    sudo useradd -m -d /opt/$projname -s /bin/bash $projname
fi

# Install necessary packages
sudo apt install -y git $python_version-pip build-essential wget $python_version-dev $python_version-venv $python_version-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev $python_version-setuptools node-less

# Function to check if wkhtmltopdf is installed
is_wkhtmltopdf_installed() {
    if wkhtmltopdf --version 2>&1 | grep -q "wkhtmltopdf 0.12.1"; then
        return 0
    else
        return 1
    fi
}

# Check if wkhtmltopdf is installed
if is_wkhtmltopdf_installed; then
    echo "wkhtmltopdf 0.12.1.3 is already installed."
else
    # Download and install wkhtmltopdf package
    wget https://builds.wkhtmltopdf.org/0.12.1.3/wkhtmltox_0.12.1.3-1~bionic_amd64.deb
    sudo dpkg -i wkhtmltox_0.12.1.3-1~bionic_amd64.deb

    # Fix dependencies if there are errors
    if [ $? -ne 0 ]; then
        sudo apt-get install -f -y
        sudo apt --fix-broken install
        sudo dpkg -i wkhtmltox_0.12.1.3-1~bionic_amd64.deb
    fi

    # Create symbolic links for wkhtmltopdf and wkhtmltoimage
    sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
    sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
fi

# Clone Odoo repository
sudo -u $projname git clone https://www.github.com/odoo/odoo --depth 1 --branch 11.0 /opt/$projname/$projname
cd /opt/$projname

# Create virtual environment and activate it
sudo -u $projname $python_version -m venv /opt/$projname/$projname-venv
source /opt/$projname/$projname-venv/bin/activate

# Install Python dependencies
pip install wheel
pip install -r /opt/$projname/$projname/requirements.txt
pip install python-openid gdata PyPDF2

# Deactivate virtual environment
deactivate

# Create log directory and set ownership
sudo mkdir -p /var/log/$projname
sudo chown -R $projname:$projname /var/log/$projname

# Create Odoo configuration file
sudo tee /etc/$projname.conf > /dev/null << EOF
[options]
admin_passwd = admin
db_host = localhost
db_port = $db_port
db_user = $projname
db_password = $db_password
pg_path = /opt/PostgreSQL/9.6/bin
logfile = /var/log/$projname/$projname-server.log
addons_path = /opt/$projname/$projname/addons,/opt/$projname/$projname/custom_apps,/opt/$projname/$projname/test_apps
xmlrpc_port = $xmlrpc_port
log_db = True
log_db_level = warning
log_handler = :INFO
log_level = info
EOF

# Create systemd service file
sudo tee /etc/systemd/system/$projname.service > /dev/null << EOF
[Unit]
Description=$projname Odoo Version 01/21/2021 Source Code
Requires=$postgresql.service 
After=network.target $postgresql.service 

[Service]
Type=simple
SyslogIdentifier=$projname
PermissionsStartOnly=true
User=$projname
Group=$projname
ExecStart=/opt/$projname/$projname-venv/bin/$python_version /opt/$projname/$projname/odoo-bin -c /etc/$projname.conf --logfile /var/log/$projname/$projname-server.log
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon and start Odoo service
sudo systemctl daemon-reload
sudo systemctl start $projname

# Check status of Odoo service
sudo systemctl status $projname

# Enable Odoo service to start on boot
sudo systemctl enable $projname

# Configure firewall
sudo ufw allow 8029/tcp
sudo ufw disable 
sudo ufw enable

echo "Odoo 11 installation script completed."


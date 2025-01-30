# HOW TO USE IT
#Before running the script, you need to make it executable:
# chmod +x uninstall_odoo.sh

#To uninstall your Odoo project, simply execute the script:
# ./uninstall_odoo_v11.sh

#-------------------------

#!/bin/bash

# Stop and disable the systemd service
sudo systemctl stop mrV11
sudo systemctl disable mrV11

# Remove the systemd service file
sudo rm /etc/systemd/system/mrV11.service
sudo systemctl daemon-reload

# Remove the Odoo installation directory
sudo rm -rf /opt/mrV11

# Remove the log directory
sudo rm -rf /var/log/mrV11

# Remove the Odoo configuration file
sudo rm /etc/mrV11.conf

# Remove the user (if created)
sudo userdel -r mrV11

echo "Odoo project uninstallation completed."





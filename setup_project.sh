#!/bin/bash
# Script for creating users, groups, configuring sudo permissions and SSH

# 1. Create groups
sudo groupadd system_admin
sudo groupadd db_admin
sudo groupadd net_admin

# 2. Create users and add them to corresponding groups
sudo useradd -m -G system_admin systemadmin_user
sudo useradd -m -G db_admin dbadmin_user
sudo useradd -m -G net_admin netadmin_user
sudo useradd -m automation_user

# 3. Set passwords automatically 
echo "systemadmin_user:Akmarzhan14" | sudo chpasswd
echo "dbadmin_user:Akmarzhan14" | sudo chpasswd
echo "netadmin_user:Akmarzhan14" | sudo chpasswd
echo "automation_user:Akmarzhan14" | sudo chpasswd

# 4. Configure sudo permissions
echo "%system_admin ALL=(ALL) ALL" | sudo tee /etc/sudoers.d/system_admin
echo "%db_admin ALL=(ALL) /usr/bin/psql, /usr/bin/createdb, /usr/bin/dropdb" | sudo tee /etc/sudoers.d/db_admin
echo "%net_admin ALL=(ALL) /usr/bin/firewall-cmd, /usr/bin/systemctl restart sshd" | sudo tee /etc/sudoers.d/net_admin
echo "automation_user ALL=(ALL) NOPASSWD: /usr/bin/git pull, /bin/systemctl restart django" | sudo tee /etc/sudoers.d/automation_user

# 5. Generate SSH key pair for automation_user
sudo -u automation_user ssh-keygen -t rsa -b 4096 -C "automation_user@project" -N "" -f /home/automation_user/.ssh/id_rsa

# 6. Set proper permissions for SSH directory and keys
sudo chmod 700 /home/automation_user/.ssh
sudo chmod 600 /home/automation_user/.ssh/id_rsa
sudo chmod 644 /home/automation_user/.ssh/id_rsa.pub
sudo chown -R automation_user:automation_user /home/automation_user/.ssh

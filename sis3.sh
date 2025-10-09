#!/bin/bash

# Update system
sudo dnf update -y

# Install main packages
sudo dnf install -y python3 python3-pip postgresql postgresql-server postgresql-contrib
sudo dnf install -y firewalld fail2ban wget curl git vim redis

# Install Python packages
pip install django psycopg2 celery redis

# Start firewall and open ports
sudo systemctl start firewalld
sudo systemctl enable firewalld

sudo firewall-cmd --zone=FedoraWorkstation --add-service=http --permanent
sudo firewall-cmd --zone=FedoraWorkstation --add-service=ssh
sudo firewall-cmd --zone=FedoraWorkstation --remove-port=1025-65535/tcp --permanent
sudo firewall-cmd --zone=FedoraWorkstation --remove-port=1025-65535/udp --permanent
sudo firewall-cmd --zone=FedoraWorkstation --add-port=5432/tcp --permanent
sudo firewall-cmd --zone=FedoraWorkstation --add-port=6379/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --zone=FedoraWorkstation --list-all

# 5. Checking
python3 --version
pip3 --version

echo -e "\nChecking Python packages..."
pip3 list | grep Django
pip3 list | grep celery
pip3 list | grep redis
pip3 list | grep psycopg2

echo -e "\nChecking services..."
systemctl status postgresql
systemctl status redis
systemctl status nginx
systemctl status httpd
systemctl status sshd

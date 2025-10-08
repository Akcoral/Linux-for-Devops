#!/bin/bash

echo " Smoke Test"

# Проверка Python и pip
python3 --version
pip3 --version

# Проверка ключевых пакетов
echo -e "\nChecking Python packages..."
pip3 list | grep Django
pip3 list | grep celery
pip3 list | grep redis
pip3 list | grep psycopg2

# Проверка сервисов
echo -e "\nChecking services..."
systemctl status postgresql
systemctl status redis
systemctl status nginx
systemctl status httpd
systemctl status sshd

echo -e "\nSmoke test finished!"

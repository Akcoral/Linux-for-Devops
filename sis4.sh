#!/bin/bash
# Yстановка Docker, создание Dockerfile, systemd, cron

# Подготовка: обновление системы
sudo dnf update -y

# 1.Установка Docker на Fedora
sudo dnf -y install dnf-plugins-core

# Добавление Docker репозитория
sudo tee /etc/yum.repos.d/docker-ce.repo << 'EOF'
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://download.docker.com/linux/fedora/$releasever/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOF

sudo dnf5 makecache
sudo dnf5 install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Включаем и запускаем Docker
sudo systemctl enable docker
sudo systemctl start docker

# Вход в Docker Hub
sudo docker login

# Создание проекта и Dockerfile
FROM fedora:latest

RUN dnf -y update && \
    dnf -y install python3 python3-pip python3-devel gcc postgresql-devel && \
    dnf clean all

WORKDIR /app

COPY requirements.txt .

RUN pip3 install --upgrade pip && \
    pip3 install -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["gunicorn", "easycode.wsgi:application", "--bind", "0.0.0.0:8000"]


mkdir -p ~/myapp/scripts
cd ~/myapp

cat > Dockerfile << 'EOF'
FROM fedora:latest
RUN dnf update -y && dnf install -y python3
WORKDIR /app
RUN echo "Hello from image!" > hello.txt
CMD ["cat", "hello.txt"]
EOF

# Сборка образа
docker build -t akmarzhan14/eeasycode:latest .

# 2. Создание systemd unit
cat > easycode.service << 'EOF'
[Unit]
Description=Docker Container
After=network-online.target docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run --name easycode -p 8080:80 akmarzhan14/eeasycode:latest
ExecStop=/usr/bin/docker stop easycode
ExecStopPost=/usr/bin/docker rm -f easycode

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable easycode
sudo systemctl start easycode
sudo systemctl status easycode

#3. Создание скриптов cron
cat > Scripts/backup.sh << 'EOF'
#!/bin/bash
tar -czf ~/backup_$(date +%F_%H-%M-%S).tar.gz ~/eeasycode
echo "Backup created at $(date)" >> ~/eeasycode/Scripts/backup.log
EOF

cat > Scripts/logtime.sh << 'EOF'
#!/bin/bash
echo "Current time: $(date)" >> ~/eeasycode/Scripts/time.log
EOF

chmod +x Scripts/*.sh

# Настройка cron
(crontab -l 2>/dev/null; echo "0 0 * * * ~/eeasycode/Scripts/backup.sh") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * * ~/eeasycode/Scripts/logtime.sh") | crontab -

echo "All steps completed! Easycode project is ready."

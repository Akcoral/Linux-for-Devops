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
FROM python:3.11-alpine

# Устанавливаем необходимые системные пакеты
RUN apk add --no-cache bash dumb-init

# Создаем пользователя
RUN addgroup -S easycode && adduser -S easycode -G easycode

# Рабочая директория
WORKDIR /app

# Копируем зависимости
COPY requirements.txt .

# Устанавливаем Python зависимости глобально
RUN pip install --no-cache-dir -r requirements.txt

# Копируем проект
COPY . .

# Меняем владельца на easycode
RUN chown -R easycode:easycode /app

# Используем пользователя easycode
USER easycode

# Команда запуска (предположим, у тебя gunicorn)
CMD ["dumb-init", "gunicorn", "--bind", "0.0.0.0:8000", "myapp.wsgi:application"]



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

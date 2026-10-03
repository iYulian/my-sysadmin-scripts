#!/usr/bin/env bash

# Переменные пути относительно bootstrap.sh
PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$PROJECT_DIR"
DISK_DIR=/var/lib/my-app-lab
DISK_FILE="$DISK_DIR/disk-lvm.img"

# 1. Инструменты хоста. Python/Nginx/OpenSSL устанавливает Dockerfile в образ.
export DEBIAN_FRONTEND=noninteractive #отключает интерактивные диалоги
export NEEDRESTART_MODE=a #автоматически перезапускать службы
apt-get update
apt-get install -y lvm2 util-linux e2fsprogs curl docker.io
systemctl enable --now docker.service

# 1. Собираем проект
docker build -t my-sysadmin-scripts:latest .

# 2. Файл 512 МиБ -> loop-устройство -> LVM-том
mkdir -p "$DISK_DIR"
dd if=/dev/zero of="$DISK_FILE" bs=1M count=512 status=progress
LOOP_DEVICE=$(losetup --find --show "$DISK_FILE")
pvcreate --yes "$LOOP_DEVICE"
vgcreate vg_data "$LOOP_DEVICE"
lvcreate --yes -L 200M -n lv_logs vg_data
mkfs.ext4 /dev/vg_data/lv_logs
mkdir /mnt/logs
mount /dev/vg_data/lv_logs /mnt/logs

# 3. Создаём контейнер
docker create --name my-app --restart=no \
    -p 127.0.0.1:80:80 \
    -p 127.0.0.1:443:443 \
    -p 127.0.0.1:8080:8080 \
    my-sysadmin-scripts:latest

# 4. Создаем службу
cat > /etc/systemd/system/my-app.service <<'UNIT'
[Unit]
Description=My sysadmin container
After=docker.service
Requires=docker.service

[Service]
Type=simple
ExecStart=/usr/bin/docker -H unix:///var/run/docker.sock start -a my-app
ExecStop=/usr/bin/docker -H unix:///var/run/docker.sock stop -t 10 my-app
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload #обеовляем службы
systemctl enable --now my-app.service #включаем службу и добавляем ей автозапуск

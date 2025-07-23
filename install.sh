#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/Luffyz618/Docker-compose/main"

SUDO=""
if [ "$EUID" -ne 0 ]; then
  SUDO="sudo"
fi

install_docker() {
  echo "🔧 正在安装 Docker 和 Compose 插件..."
  $SUDO apt-get update
  $SUDO apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

  $SUDO mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
    $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

  $SUDO apt-get update
  $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  echo "✅ Docker 安装完成。"
}

if ! command -v docker &> /dev/null; then
  install_docker
else
  echo "✅ 已安装 Docker。"
fi

if ! docker compose version &> /dev/null; then
  echo "❌ 未检测到 docker compose 插件，正在安装..."
  $SUDO apt-get install -y docker-compose-plugin
  if ! docker compose version &> /dev/null; then
    echo "❌ 安装失败，请手动安装 docker compose。"
    exit 1
  fi
else
  echo "✅ 已安装 Docker Compose 插件。"
fi

echo
echo "请选择要安装的服务："
echo "0 - 安装全部"
echo "1 - Emby"
echo "2 - MoviePilot"
echo "3 - IYUU"
echo "4 - qBittorrent"
read -p "请输入数字 (0-4): " choice

declare -A services=(
  [1]="emby.yaml"
  [2]="mp.yaml"
  [3]="iyuu.yaml"
  [4]="qbittorrent.yaml"
)

install_service() {
  filename=$1
  dirname="${filename%.*}"
  echo "📦 正在安装：$filename"
  mkdir -p "$dirname"
  curl -fsSL "$REPO_URL/$filename" -o "$dirname/$filename"
  (cd "$dirname" && docker compose -f "$filename" up -d)
  echo "✅ 安装完成：$filename"
  echo
}

if [[ "$choice" == "0" ]]; then
  for i in 1 2 3 4; do
    install_service "${services[$i]}"
  done
elif [[ "$choice" =~ ^[1-4]$ ]]; then
  install_service "${services[$choice]}"
else
  echo "❌ 输入无效，请输入 0~4 的数字。"
  exit 1
fi


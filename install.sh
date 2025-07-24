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
echo "请选择要安装的服务（可组合输入，如 1 3 或 1,2,4）："
echo "0 - 安装全部"
echo "1 - Emby"
echo "2 - MoviePilot"
echo "3 - IYUU"
echo "4 - qBittorrent"
read -p "请输入数字 (0-4): " input

declare -A services=(
  [1]="emby.yaml"
  [2]="moviepilot.yaml"
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

  # 获取内网 IP 地址
  LOCAL_IP=$(hostname -I | awk '{print $1}')

  # 检查是否使用 host 网络模式
  if grep -q "network_mode: host" "$dirname/$filename"; then
    # 提取 environment 中的 PORT/NGINX_PORT
    env_port=$(grep -E 'NGINX_PORT=|PORT=' "$dirname/$filename" | grep -oE '[0-9]{2,5}' | head -n 1)
    if [[ -n "$env_port" ]]; then
      echo "🌐 $dirname 可访问：http://$LOCAL_IP:$env_port"
    else
      echo "ℹ️ $dirname 使用 host 网络，但未检测到明确端口，请手动确认。"
    fi
  else
    # 提取 compose 中的第一个端口映射
    host_port=$(grep -oE '[- ]+["]?[0-9]{2,5}:[0-9]{2,5}["]?' "$dirname/$filename" | \
                sed -E 's/[^0-9]*([0-9]{2,5}):[0-9]{2,5}.*/\1/' | head -n 1)
    if [[ -n "$host_port" ]]; then
      echo "🌐 $dirname 可访问：http://$LOCAL_IP:$host_port"
    else
      echo "ℹ️ $dirname 没有找到端口映射或无 Web 界面"
    fi
  fi

  # 查看日志
  echo "📜 查看日志请输入：docker logs -f $dirname"
  echo "或者使用 docker-compose logs $dirname 来查看容器日志"

  echo
}

# 处理组合输入（空格或逗号分隔）
input_clean=$(echo "$input" | tr ',' ' ')
choices=()
for i in $input_clean; do
  if [[ "$i" =~ ^[0-4]$ ]]; then
    choices+=("$i")
  else
    echo "⚠️ 无效选项已忽略: $i"
  fi
done

# 如果包含 0，则安装全部服务
if [[ " ${choices[*]} " =~ " 0 " ]]; then
  choices=(1 2 3 4)
fi

# 去重
unique_choices=($(echo "${choices[@]}" | tr ' ' '\n' | sort -n | uniq))

if [ ${#unique_choices[@]} -eq 0 ]; then
  echo "❌ 未选择任何有效服务，退出。"
  exit 1
fi

# 安装所选服务
for i in "${unique_choices[@]}"; do
  install_service "${services[$i]}"
done

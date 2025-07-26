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

# ========== 卸载逻辑 ==========
if [[ "$1" == "--uninstall" ]]; then
  echo "🧹 进入卸载模式"
  echo "请选择要卸载的服务（可组合输入，如 1 3 或 1,2,4）："
  echo "0 - 卸载全部"
  echo "1 - Emby"
  echo "2 - MoviePilot"
  echo "3 - IYUU"
  echo "4 - qBittorrent"
  echo "5 - Plex"
  echo "6 - Lucky"
  echo "7 - Jellyseerr"
  echo "8 - FileBrowser"
  echo "9 - Transmission"
  read -p "请输入数字 (0-9): " input

  declare -A services=(
    [1]="emby.yaml"
    [2]="moviepilot.yaml"
    [3]="iyuu.yaml"
    [4]="qbittorrent.yaml"
    [5]="plex.yaml"
    [6]="lucky.yaml"
    [7]="jellyseerr.yaml"
    [8]="filebrowser.yaml"
    [9]="transmission.yaml"
  )

  declare -A images=(
    [1]="emby/embyserver"
    [2]="ghcr.io/moviepilot/moviepilot"
    [3]="iyuucn/iyuuplus"
    [4]="linuxserver/qbittorrent"
    [5]="plexinc/pms-docker"
    [6]="luckyz0311/lucky"
    [7]="fallenbagel/jellyseerr"
    [8]="filebrowser/filebrowser"
    [9]="linuxserver/transmission"
  )

  input_clean=$(echo "$input" | tr ',' ' ')
  choices=()
  for i in $input_clean; do
    if [[ "$i" =~ ^[0-9]$ ]]; then
      choices+=("$i")
    else
      echo "⚠️ 无效选项已忽略: $i"
    fi
  done

  if [[ " ${choices[*]} " =~ " 0 " ]]; then
    choices=(1 2 3 4 5 6 7 8 9)
  fi

  unique_choices=($(echo "${choices[@]}" | tr ' ' '\n' | sort -n | uniq))

  if [ ${#unique_choices[@]} -eq 0 ]; then
    echo "❌ 未选择任何有效服务，退出。"
    exit 1
  fi

  for i in "${unique_choices[@]}"; do
    filename="${services[$i]}"
    dirname="${filename%.*}"
    imagename="${images[$i]}"

    echo "🔻 停止并删除服务 $dirname ..."

    if [ -f "$dirname/$filename" ]; then
      (cd "$dirname" && docker compose -f "$filename" down)
    else
      docker rm -f "$dirname" &>/dev/null
    fi

    echo "🗑 删除目录 $dirname 及全部内容..."
    rm -rf "$dirname"

    echo "🧼 删除镜像 $imagename ..."
    docker rmi -f "$imagename" 2>/dev/null

    echo "✅ 卸载完成：$dirname"
  done

  echo "🚪 所选服务已全部卸载完毕。"
  exit 0
fi
# ========== 结束卸载逻辑 ==========

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
echo "5 - Plex"
echo "6 - Lucky"
echo "7 - Jellyseerr"
echo "8 - FileBrowser"
echo "9 - Transmission"
read -p "请输入数字 (0-9): " input

declare -A services=(
  [1]="emby.yaml"
  [2]="moviepilot.yaml"
  [3]="iyuu.yaml"
  [4]="qbittorrent.yaml"
  [5]="plex.yaml"
  [6]="lucky.yaml"
  [7]="jellyseerr.yaml"
  [8]="filebrowser.yaml"
  [9]="transmission.yaml"
)

declare -A service_ips=()
declare -A container_names=()

install_service() {
  filename=$1
  dirname="${filename%.*}"

  existing_container=$(docker ps -a --filter "name=^${dirname}$" --format '{{.Names}}')
  if [[ "$existing_container" == "$dirname" ]]; then
    echo "⚠️ 服务 $dirname 容器已存在，跳过安装。"
    container_names["$filename"]=$dirname
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    case "$filename" in
      plex.yaml)
        service_ips["$filename"]="http://$LOCAL_IP:32400"
        ;;
      lucky.yaml)
        service_ips["$filename"]="http://$LOCAL_IP:16601"
        ;;
      *)
        ports=$(docker port "$dirname" 2>/dev/null | head -n1)
        if [[ -n "$ports" ]]; then
          host_port=$(echo "$ports" | sed -E 's/.*:(.*)/\1/')
          service_ips["$filename"]="http://$LOCAL_IP:$host_port"
        else
          service_ips["$filename"]="ℹ️ $dirname 已存在，但未能自动检测端口，请手动确认。"
        fi
        ;;
    esac
    return
  fi

  echo "📦 正在安装：$filename"
  mkdir -p "$dirname"
  curl -fsSL "$REPO_URL/$filename" -o "$dirname/$filename"

  (cd "$dirname" && docker compose -f "$filename" up -d)

  echo "✅ 安装完成：$filename"

  LOCAL_IP=$(hostname -I | awk '{print $1}')

  case "$filename" in
    plex.yaml)
      service_ips["$filename"]="http://$LOCAL_IP:32400"
      ;;
    lucky.yaml)
      service_ips["$filename"]="http://$LOCAL_IP:16601"
      ;;
    *)
      if grep -q "network_mode: host" "$dirname/$filename"; then
        env_port=$(grep -E 'NGINX_PORT=|PORT=' "$dirname/$filename" | grep -oE '[0-9]{2,5}' | head -n 1)
        if [[ -n "$env_port" ]]; then
          service_ips["$filename"]="http://$LOCAL_IP:$env_port"
        else
          service_ips["$filename"]="ℹ️ $dirname 使用 host 网络，但未检测到明确端口，请手动确认。"
        fi
      else
        host_port=$(grep -oE '[- ]+["]?[0-9]{2,5}:[0-9]{2,5}["]?' "$dirname/$filename" | \
                    sed -E 's/[^0-9]*([0-9]{2,5}):[0-9]{2,5}.*/\1/' | head -n 1)
        if [[ -n "$host_port" ]]; then
          service_ips["$filename"]="http://$LOCAL_IP:$host_port"
        else
          service_ips["$filename"]="ℹ️ $dirname 没有找到端口映射或无 Web 界面"
        fi
      fi
      ;;
  esac

  container_name=$(docker ps --filter "name=$dirname" --format "{{.Names}}")
  container_names["$filename"]=$container_name
}

input_clean=$(echo "$input" | tr ',' ' ')
choices=()
for i in $input_clean; do
  if [[ "$i" =~ ^[0-9]$ ]]; then
    choices+=("$i")
  else
    echo "⚠️ 无效选项已忽略: $i"
  fi
done

if [[ " ${choices[*]} " =~ " 0 " ]]; then
  choices=(1 2 3 4 5 6 7 8 9)
fi

unique_choices=($(echo "${choices[@]}" | tr ' ' '\n' | sort -n | uniq))

if [ ${#unique_choices[@]} -eq 0 ]; then
  echo "❌ 未选择任何有效服务，退出。"
  exit 1
fi

for i in "${unique_choices[@]}"; do
  install_service "${services[$i]}"
done

echo
echo "所有服务安装完成，以下是可访问的服务 IP 地址："
for i in "${unique_choices[@]}"; do
  filename="${services[$i]}"
  echo "$filename: ${service_ips[$filename]}"
  if [[ "$filename" == "transmission.yaml" ]]; then
    echo "  默认用户名：admin"
    echo "  默认密码：password"
  fi
done

echo
echo "📜 查看日志的方法："
for service in "${!container_names[@]}"; do
  container_name="${container_names[$service]}"
  echo "查看 $service 的日志请输入：docker logs -f $container_name"
done

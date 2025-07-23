install_service() {
  filename=$1
  dirname="${filename%.*}"
  echo "📦 正在安装：$filename"
  mkdir -p "$dirname"
  curl -fsSL "$REPO_URL/$filename" -o "$dirname/$filename"

  (cd "$dirname" && docker compose -f "$filename" up -d)

  echo "✅ 安装完成：$filename"

  # 取内网 IP
  LOCAL_IP=$(hostname -I | awk '{print $1}')

  # 根据服务名显示默认端口
  case "$dirname" in
    emby)
      PORT=8096
      echo "🌐 Emby 已部署，可访问：http://$LOCAL_IP:$PORT"
      ;;
    mp)
      PORT=3000
      echo "🌐 MoviePilot 已部署，可访问：http://$LOCAL_IP:$PORT"
      ;;
    iyuu)
      PORT=8787
      echo "🌐 IYUU 已部署（可能无 Web 界面），默认端口：$PORT"
      ;;
    qbittorrent)
      PORT=8080
      echo "🌐 qBittorrent 已部署，可访问：http://$LOCAL_IP:$PORT"
      ;;
    *)
      echo "ℹ️ 服务 $dirname 安装完成，但未配置端口提示。"
      ;;
  esac

  echo
}

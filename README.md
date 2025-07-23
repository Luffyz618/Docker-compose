# 📦 一键安装 Docker 应用

本仓库包含 4 个基于 Docker Compose 的服务部署配置文件：

- Emby
- MoviePilot
- IYUU
- qBittorrent

你可以使用下面的命令一键安装任意一个或全部服务。

---

## 🚀 快速开始（推荐）

复制并粘贴以下命令运行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Luffyz618/Docker-compose/main/install.sh)

##📋 使用方法
运行脚本后会提示你选择要安装的服务：
请选择要安装的服务：
0 - 安装全部
1 - Emby
2 - MoviePilot
3 - IYUU
4 - qBittorrent
输入对应的数字后回车即可。

脚本会为每个服务执行以下操作：

自动创建同名文件夹（例如：emby）

下载对应的 .yaml 配置文件

执行 docker compose up -d 启动服务

##📎 前提条件
无需手动安装 Docker 和 Docker Compose，脚本会自动检测系统环境并执行：

如果未安装 Docker，会自动安装最新版

如果未安装 Docker Compose 插件，也会自动安装

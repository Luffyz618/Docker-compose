🚀 一键安装 Docker 服务脚本

零基础更详细的使用方法以及更多应用教程，请前往微信公众号：手把手教程查看

<img src="assets/preview.jpg" alt="公众号" width="300">

本脚本用于一键安装 Docker 及 Docker Compose 插件，并可选择性部署多个常用服务（如 Emby、MoviePilot、IYUU、qBittorrent）。

📦 支持的服务列表
| 序号 | 服务名称     | 默认端口 | 简介                          |
|------|--------------|----------|-------------------------------|
| 1    | Emby         | 8096     | 媒体服务器，可用于家庭影音中心 |
| 2    | MoviePilot   | 3000     | 自动电影信息获取与整理工具   |
| 3    | IYUU         | 8780     | PT 辅助工具，用于辅种、自动转移做种 |
| 4    | qBittorrent  | 8080     | 高性能 BT 下载客户端         |


📋 脚本功能
自动检测并安装 Docker 和 Compose 插件

自动拉取对应服务的 Docker Compose 文件

支持批量或单项选择部署服务

自动创建服务目录并运行容器

自动输出访问地址

🧰 环境要求
系统：Debian/Ubuntu 等基于 APT 的 Linux 发行版

权限：支持自动检测是否需要 sudo

依赖工具：curl, gpg, lsb-release, docker, docker compose

🚀 使用方法
打开终端，ssh连接到NAS或者VPS执行以下命令运行脚本：

```
bash <(curl -fsSL https://raw.githubusercontent.com/Luffyz618/Docker-compose/main/install.sh)
```
按提示输入要安装的服务编号，例如：


```
请输入数字 (0-4): 1 3
```
输入 0 安装全部服务

可输入多个服务编号，用空格或逗号分隔

安装完成后，终端会显示每个服务的访问地址，例如：
```
🌐 emby 可访问：http://192.168.1.100:8096
```

❗ 注意事项
若网络不稳定，curl 下载可能失败，请重试或使用代理。

安装服务前请确认系统端口未被占用。

脚本仅供学习测试，部署在公网前请加强安全配置。

📄 License
本脚本基于 MIT 协议开源，欢迎自由使用与修改。

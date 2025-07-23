#!/bin/bash

mkdir -p beszel && cd beszel

# 从GitHub下载docker-compose.yml
echo "正在从GitHub下载配置文件..."
curl -O https://raw.githubusercontent.com/Luffyz618/Docker-compose/main/beszel.yaml

# 启动容器
echo "正在启动Beszel容器..."
 docker-compose -f beszel.yaml up -d

echo "安装完成！Beszel服务已在端口8090运行"

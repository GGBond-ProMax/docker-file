#!/bin/bash

# 定义升级所需的变量
OLD_ES_CONTAINER="docker-es"
NEW_ES_IMAGE="elasticsearch:7.17.19"  # 修改为 7.17.19 版本
SNAPSHOT_REPO_NAME="es_backup"
ES_DATADIR="/esdatadir"
CONFIG_DIR="${ES_DATADIR}/config"
DATA_DIR="${ES_DATADIR}/data"
LOGS_DIR="${ES_DATADIR}/logs"
SNAPSHOT_DIR="${ES_DATADIR}/snapshot"
ES_HOST="http://localhost:9200"
ES_USER="elastic"
ES_PASS="123456"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，请先安装 Docker。"
    exit 1
fi

# 检查现有的Elasticsearch容器是否正在运行
if [ "$(docker ps -q -f name=$OLD_ES_CONTAINER)" ]; then
    echo "停止并移除当前运行的 Elasticsearch 容器..."
    docker stop $OLD_ES_CONTAINER
    docker rm $OLD_ES_CONTAINER
fi

# 拉取新的 Elasticsearch 镜像
echo "拉取新的 Elasticsearch 镜像 ${NEW_ES_IMAGE}..."
docker pull $NEW_ES_IMAGE

# 恢复数据
echo "恢复数据..."
docker run --restart=always \
    -p 9200:9200 \
    -e "discovery.type=single-node" \
    -e "ELASTIC_PASSWORD=123456" \
    -e ES_JAVA_OPTS="-Xms1g -Xmx1g" \
    --name docker-es \
    -d \
    -v "$CONFIG_DIR:/usr/share/elasticsearch/config" \
    -v "$DATA_DIR:/usr/share/elasticsearch/data" \
    -v "$LOGS_DIR:/usr/share/elasticsearch/logs" \
    -v "$SNAPSHOT_DIR:/usr/share/elasticsearch/snapshot" \
    $NEW_ES_IMAGE

# 检查 Elasticsearch 服务是否正常启动
echo "等待 Elasticsearch 服务启动..."

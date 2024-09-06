#!/bin/bash

# 定义 Elasticsearch 相关变量
ES_HOST="http://localhost:9200"
ES_USER="elastic"
ES_PASS="123456"
SNAPSHOT_REPO_NAME="es_backup"
SNAPSHOT_NAME="snapshot_$(date +%Y%m%d%H%M%S)"
SNAPSHOT_DIR="/usr/share/elasticsearch/snapshot"

# 将 path.repo 写入配置文件
echo "写入 path.repo 到配置文件..."
echo 'path.repo: ["/usr/share/elasticsearch/snapshot"]' >> /esdatadir/config/elasticsearch.yml

# 检查 Docker 是否运行
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，请先安装 Docker。"
    exit 1
fi

# 检查快照目录是否存在
if [ ! -d "$SNAPSHOT_DIR" ]; then
    echo "快照目录不存在，正在创建..."
    mkdir -p "$SNAPSHOT_DIR"
    chown -R 1000:1000 "$SNAPSHOT_DIR"  # 确保 Elasticsearch 用户拥有权限
fi

# 检查快照仓库是否存在
repository_exists() {
    echo "检查快照仓库是否存在..."

    response=$(curl -u "$ES_USER:$ES_PASS" -s -o /dev/null -w "%{http_code}" "$ES_HOST/_snapshot/$SNAPSHOT_REPO_NAME")

    if [ "$response" -eq 200 ]; then
        echo "快照仓库已存在"
        return 0
    elif [ "$response" -eq 404 ]; then
        echo "快照仓库不存在"
        return 1
    else
        echo "无法检查快照仓库状态"
        exit 1
    fi
}

# 创建快照仓库
create_repository() {
    echo "创建快照仓库..."

    curl -u "$ES_USER:$ES_PASS" -X PUT "$ES_HOST/_snapshot/$SNAPSHOT_REPO_NAME" -H 'Content-Type: application/json' -d'
    {
      "type": "fs",
      "settings": {
        "location": "'"$SNAPSHOT_DIR"'",
        "compress": true
      }
    }
    '

    if [ $? -eq 0 ]; then
        echo "快照仓库创建成功"
    else
        echo "快照仓库创建失败"
        exit 1
    fi
}

# 创建快照
create_snapshot() {
    echo "创建快照..."

    curl -u "$ES_USER:$ES_PASS" -X PUT "$ES_HOST/_snapshot/$SNAPSHOT_REPO_NAME/$SNAPSHOT_NAME?wait_for_completion=true" -H 'Content-Type: application/json' -d'
    {
      "indices": "*",
      "ignore_unavailable": true,
      "include_global_state": true
    }
    '

    if [ $? -eq 0 ]; then
        echo "快照创建成功"
    else
        echo "快照创建失败"
        exit 1
    fi
}

# 执行备份
if ! repository_exists; then
    create_repository
fi
create_snapshot
echo "备份完成，快照名称: $SNAPSHOT_NAME"


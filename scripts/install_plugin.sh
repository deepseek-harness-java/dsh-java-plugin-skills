#!/usr/bin/env bash
# 安装并激活 DSH Java Native 插件
# 用法: bash install_plugin.sh <插件JAR绝对路径> <pluginId> <版本> <入口JAR文件名> [displayName]
# 示例: bash install_plugin.sh /path/mall-agent-plugin-1.0.0-SNAPSHOT.jar mall-weekend-assistant 1.0.0-SNAPSHOT mall-agent-plugin-1.0.0-SNAPSHOT.jar "2D Weekend Mall Assistant"
set -euo pipefail

JAR="${1:?用法: install_plugin.sh <插件JAR绝对路径> <pluginId> <版本> <入口JAR文件名> [displayName]}"
PLUGIN_ID="${2:?缺少 pluginId}"
VERSION="${3:?缺少 版本}"
ENTRY_JAR="${4:?缺少 入口JAR文件名}"
DISPLAY="${5:-$PLUGIN_ID}"
HARNESS="${DSH_HARNESS_URL:-http://127.0.0.1:8090}"

JAR="$(cd "$(dirname "$JAR")" && pwd)/$(basename "$JAR")"
if [ ! -f "$JAR" ]; then echo "[FAIL] JAR 不存在: $JAR"; exit 1; fi

echo "[INFO] 安装插件 $PLUGIN_ID ($JAR)"
curl -fsS -X POST "$HARNESS/api/harness/plugins/install" \
  -H 'Content-Type: application/json' \
  -d "{\"pluginId\":\"$PLUGIN_ID\",\"displayName\":\"$DISPLAY\",\"pluginVersion\":\"$VERSION\",\"runtimeType\":\"JAVA_NATIVE\",\"sourcePath\":\"$JAR\",\"entrypoint\":\"$ENTRY_JAR\"}"
echo

echo "[INFO] 激活插件"
curl -fsS -X POST "$HARNESS/api/harness/plugins/activate" \
  -H 'Content-Type: application/json' \
  -d "{\"pluginId\":\"$PLUGIN_ID\"}"
echo

echo "[OK] 完成。验证: curl $HARNESS/api/harness/plugins"

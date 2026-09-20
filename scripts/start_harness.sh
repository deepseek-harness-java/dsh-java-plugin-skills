#!/usr/bin/env bash
# 启动 deepseek-harness-java（端口 8090）
# 用法: bash start_harness.sh [jar路径]   默认使用技能内 runtime/deepseek-harness-java-app.jar
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAR="${1:-$SCRIPT_DIR/../runtime/deepseek-harness-java-app.jar}"
PORT=8090

if curl -fsS -o /dev/null --max-time 3 "http://127.0.0.1:$PORT"; then
  echo "[SKIP] 端口 $PORT 已有服务在运行: http://127.0.0.1:$PORT"
  exit 0
fi

if [ ! -f "$JAR" ]; then
  echo "[FAIL] 未找到 JAR: $JAR"
  exit 1
fi

echo "[INFO] 启动 DSH: $JAR"
nohup java -jar "$JAR" > /tmp/dsh-harness.log 2>&1 &
echo $! > /tmp/dsh-harness.pid

for i in $(seq 1 60); do
  if curl -fsS -o /dev/null --max-time 2 "http://127.0.0.1:$PORT"; then
    echo "[OK] DSH 已启动: http://127.0.0.1:$PORT (pid $(cat /tmp/dsh-harness.pid))"
    echo "[TIP] 请到 控制台 -> 设置 -> 模型设置 配置模型地址/API Key 后再对话"
    exit 0
  fi
  sleep 1
done

echo "[FAIL] 启动超时，查看日志: tail -100 /tmp/dsh-harness.log"
exit 1

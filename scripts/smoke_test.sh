#!/usr/bin/env bash
# 冒烟验证：DSH 服务与插件状态
set -u
HARNESS="${DSH_HARNESS_URL:-http://127.0.0.1:8090}"

curl -fsS -o /dev/null --max-time 3 "$HARNESS" \
  && echo "[OK] DSH 可访问: $HARNESS" \
  || { echo "[FAIL] DSH 不可访问: $HARNESS"; exit 1; }

echo "[INFO] 已安装插件:"
curl -fsS "$HARNESS/api/harness/plugins" || { echo "[FAIL] 插件接口调用失败"; exit 1; }
echo

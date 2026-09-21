#!/usr/bin/env bash
# 最终交付自动化检查：探活 + 插件状态 + 鉴权回归
# 用法: delivery_check.sh <pluginId> [应用地址] [DSH地址] [写探测路径] [读探测路径]
# 默认: 应用 http://127.0.0.1:18081  DSH http://127.0.0.1:8090
#       写探测 /api/ledger/transactions  读探测 /api/ledger/summary?month=2026-09
# 退出码: 0=全部通过, 1=有失败项
set -uo pipefail

PLUGIN_ID="${1:?用法: delivery_check.sh <pluginId> [应用地址] [DSH地址] [写探测路径] [读探测路径]}"
APP="${2:-http://127.0.0.1:18081}"
DSH="${3:-http://127.0.0.1:8090}"
WRITE_PATH="${4:-/api/ledger/transactions}"
READ_PATH="${5:-/api/ledger/summary}"

export no_proxy='127.0.0.1,localhost' NO_PROXY='127.0.0.1,localhost'
FAIL=0

code() { curl -s --noproxy '*' -o /dev/null -w "%{http_code}" --max-time 5 "$1"; }

echo "== 1/5 DSH 探活 =="
c=$(code "$DSH/")
if [ "$c" = "200" ]; then echo "  PASS ($c) $DSH"; else echo "  FAIL ($c) — 先启动 DSH 再重跑"; FAIL=1; fi

echo "== 2/5 应用探活 =="
c=$(code "$APP/")
if [ "$c" = "200" ]; then echo "  PASS ($c) $APP"; else echo "  FAIL ($c) — 先启动应用再重跑"; FAIL=1; fi

echo "== 3/5 插件状态 ($PLUGIN_ID) =="
status=$(curl -s --noproxy '*' --max-time 5 "$DSH/api/harness/plugins" \
  | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin).get('data') or []
    m = [p for p in d if p.get('pluginId') == sys.argv[1]]
    print(m[0].get('status', 'NOT_FOUND') if m else 'NOT_FOUND')
except Exception:
    print('PARSE_ERROR')
" "$PLUGIN_ID" 2>/dev/null)
if [ "$status" = "ACTIVE" ]; then echo "  PASS (ACTIVE)"; else echo "  FAIL ($status) — 重新 install/activate"; FAIL=1; fi

echo "== 4/5 写接口鉴权回归（无 token 应 401）=="
c=$(curl -s --noproxy '*' -o /dev/null -w "%{http_code}" --max-time 5 \
  -X POST "$APP$WRITE_PATH" -H 'Content-Type: application/json' -d '{"probe":true}')
if [ "$c" = "401" ]; then echo "  PASS (401)"; else
  echo "  WARN ($c) — 若应用无 token 机制可忽略；有则必须 401（曾出现穿透漏洞）"
fi

echo "== 5/5 读接口探活 =="
body=$(curl -s --noproxy '*' --max-time 5 "$APP$READ_PATH")
c=$(code "$APP$READ_PATH")
if [ "$c" = "200" ] && echo "$body" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  echo "  PASS (200 且 JSON 合法)"
else
  echo "  FAIL ($c 或 JSON 非法)"; FAIL=1
fi

echo
if [ "$FAIL" = "0" ]; then
  echo "[OK] 自动化检查全部通过。继续过 references/delivery-checklist.md 的手工项（UI 真实浏览器验证 + 回归矩阵）。"
else
  echo "[FAIL] 有失败项，修复后重跑。"
fi
exit $FAIL

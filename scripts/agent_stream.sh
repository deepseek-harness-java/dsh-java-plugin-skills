#!/usr/bin/env bash
# DSH Agent 端到端流式调用 + 最终回答提取
# 用法: agent_stream.sh [host:port] [agentId] [message]
#   默认: 127.0.0.1:8090  customer-service-demo  "你好"
# 输出三段：① 工具调用轨迹 ② 工具结果摘要 ③ 最终中文回答
set -euo pipefail

HOST="${1:-127.0.0.1:8090}"
AGENT="${2:-customer-service-demo}"
MSG="${3:-你好，请介绍一下你能调用哪些工具}"

# 沙箱环境常驻 HTTP_PROXY 会导致本机 curl 502，必须绕过
export no_proxy='127.0.0.1,localhost' NO_PROXY='127.0.0.1,localhost'

PAYLOAD=$(python3 - "$AGENT" "$MSG" <<'PY'
import json, sys
print(json.dumps({"agentId": sys.argv[1], "approvalMode": "FULL_OPEN", "message": sys.argv[2]}, ensure_ascii=False))
PY
)

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

curl -s --noproxy '*' --max-time 180 -X POST "http://${HOST}/api/agent/stream" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD" > "$TMP"

echo "== 工具调用 =="
grep -A1 '^event:step_break' "$TMP" | grep '^data:' | sed 's/^data://' | while IFS= read -r line; do
  [ -z "$line" ] && continue
  python3 -c "import json,sys; d=json.loads(sys.argv[1]); print('->', d.get('toolName','?'), '| args:', json.dumps(d.get('args',{}), ensure_ascii=False)[:200])" "$line" 2>/dev/null || true
done || true

echo "== 工具结果 =="
grep -A1 '^event:tool_result' "$TMP" | grep '^data:' | sed 's/^data://' | while IFS= read -r line; do
  [ -z "$line" ] && continue
  python3 -c "import json,sys; d=json.loads(sys.argv[1]); r=str(d.get('result','')); print('<-', d.get('toolName','?'), '|', r[:300])" "$line" 2>/dev/null || true
done || true

echo "== 最终回答 =="
grep -A1 '^event:chunk' "$TMP" | grep '^data:' | sed 's/^data://' | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        print(json.loads(line).get('content', ''), end='')
    except Exception:
        pass
" || true
echo

echo "== 状态 =="
if grep -q '^event:error' "$TMP" 2>/dev/null; then
  grep -A1 '^event:error' "$TMP" | grep '^data:' | head -3 || true
elif grep -q '^event:done' "$TMP" 2>/dev/null; then
  echo "done ✓"
else
  echo "流未正常结束（检查模型配置/服务状态）"
fi

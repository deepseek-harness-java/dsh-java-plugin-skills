#!/usr/bin/env bash
# DSH 一键远程部署：上传 JAR -> 生成远端重启脚本 -> 启动 -> 探活
# 用法:
#   deploy_remote.sh -t user@host [-d /opt/dsh] [-a app.jar] [-g plugin.jar] [-s harness.jar|skip] [-P 8090] [-A 18081]
# 参数:
#   -t  目标服务器 user@host（必填）
#   -d  远端目录（默认 /opt/dsh）
#   -a  业务应用 JAR（可选，单文件；不传则只部署 DSH）
#   -g  插件 JAR（可选；上传后仍需在 DSH install+activate）
#   -s  DSH 宿主 JAR 路径（缺省用技能内置 runtime JAR；服务器已有传 skip）
#   -P  DSH 端口（默认 8090）
#   -A  应用端口（默认 18081，避开 18080/8091）
set -euo pipefail

TARGET=""; REMOTE_DIR="/opt/dsh"; APP_JAR=""; PLUGIN_JAR=""; HARNESS_JAR=""; DSH_PORT=8090; APP_PORT=18081
while getopts "t:d:a:g:s:P:A:" opt; do
  case $opt in
    t) TARGET=$OPTARG;; d) REMOTE_DIR=$OPTARG;; a) APP_JAR=$OPTARG;;
    g) PLUGIN_JAR=$OPTARG;; s) HARNESS_JAR=$OPTARG;; P) DSH_PORT=$OPTARG;; A) APP_PORT=$OPTARG;;
    *) echo "未知参数 -${opt}"; exit 1;;
  esac
done
if [ -z "$TARGET" ]; then
  echo "用法: $0 -t user@host [-d /opt/dsh] [-a app.jar] [-g plugin.jar] [-s harness.jar|skip] [-P 8090] [-A 18081]"
  exit 1
fi

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ -z "$HARNESS_JAR" ]; then HARNESS_JAR="$SKILL_DIR/runtime/deepseek-harness-java-app.jar"; fi
HOST="${TARGET#*@}"

echo "==> [1/5] SSH 连通性检查"
ssh -o ConnectTimeout=8 -o BatchMode=yes "$TARGET" "echo ok" >/dev/null || {
  echo "SSH 连不上 $TARGET：确认主机地址、密钥免密登录（ssh-copy-id）、安全组放行 22 端口"; exit 1; }

echo "==> [2/5] 上传文件到 $TARGET:$REMOTE_DIR"
ssh "$TARGET" "mkdir -p $REMOTE_DIR/logs"
if [ "$HARNESS_JAR" != "skip" ]; then
  [ -f "$HARNESS_JAR" ] || { echo "DSH JAR 不存在: $HARNESS_JAR"; exit 1; }
  scp -q "$HARNESS_JAR" "$TARGET:$REMOTE_DIR/deepseek-harness-java-app.jar"
fi
if [ -n "$APP_JAR" ]; then
  [ -f "$APP_JAR" ] || { echo "应用 JAR 不存在: $APP_JAR"; exit 1; }
  APP_NAME="$(basename "$APP_JAR")"
  scp -q "$APP_JAR" "$TARGET:$REMOTE_DIR/$APP_NAME"
else
  APP_NAME=""
fi
if [ -n "$PLUGIN_JAR" ]; then
  [ -f "$PLUGIN_JAR" ] || { echo "插件 JAR 不存在: $PLUGIN_JAR"; exit 1; }
  scp -q "$PLUGIN_JAR" "$TARGET:$REMOTE_DIR/$(basename "$PLUGIN_JAR")"
fi

echo "==> [3/5] 生成远端重启脚本（显式 --server.port 防 SERVER_PORT 劫持）"
RESTART_LOCAL="$(mktemp)"
{
  echo "#!/usr/bin/env bash"
  echo "set -e"
  echo "cd $REMOTE_DIR"
  echo "pkill -f 'deepseek-harness-java-app.jar' 2>/dev/null || true"
  [ -n "$APP_NAME" ] && echo "pkill -f '$APP_NAME' 2>/dev/null || true"
  echo "sleep 1"
  echo "nohup java -jar $REMOTE_DIR/deepseek-harness-java-app.jar --server.port=$DSH_PORT > $REMOTE_DIR/logs/dsh.log 2>&1 &"
  if [ -n "$APP_NAME" ]; then
    echo "nohup java -jar $REMOTE_DIR/$APP_NAME --server.port=$APP_PORT > $REMOTE_DIR/logs/app.log 2>&1 &"
  fi
  echo "sleep 3"
  echo "echo '重启完成。进程:'; pgrep -af 'java -jar' || true"
} > "$RESTART_LOCAL"
scp -q "$RESTART_LOCAL" "$TARGET:$REMOTE_DIR/restart_all.sh"
rm -f "$RESTART_LOCAL"
ssh "$TARGET" "chmod +x $REMOTE_DIR/restart_all.sh"

echo "==> [4/5] 启动服务"
ssh "$TARGET" "bash $REMOTE_DIR/restart_all.sh"
sleep 5

echo "==> [5/5] 探活"
probe() { curl --noproxy '*' -o /dev/null -s -m 5 -w "%{http_code}" "http://$HOST:$1" 2>/dev/null || echo "000"; }
DSH_CODE=$(probe "$DSH_PORT")
echo "DSH  http://$HOST:$DSH_PORT  -> HTTP $DSH_CODE"
if [ -n "$APP_NAME" ]; then
  APP_CODE=$(probe "$APP_PORT")
  echo "应用 http://$HOST:$APP_PORT  -> HTTP $APP_CODE"
fi

echo ""
echo "===== 部署结果 ====="
[ "$DSH_CODE" != "000" ] && echo "[OK] DSH 可访问" || echo "[FAIL] DSH 不可达：检查服务器防火墙/云安全组是否放行 $DSH_PORT"
if [ -n "$APP_NAME" ]; then
  [ "$APP_CODE" != "000" ] && echo "[OK] 应用可访问" || echo "[FAIL] 应用不可达：检查安全组是否放行 $APP_PORT，或 ssh 上去看 $REMOTE_DIR/logs/app.log"
fi
echo ""
echo "后续操作："
echo "  1. 插件安装激活: HARNESS=http://$HOST:$DSH_PORT bash $SKILL_DIR/scripts/install_plugin.sh <插件jar> <pluginId> <版本> <入口jar名>"
echo "     （或 DSH 控制台 http://$HOST:$DSH_PORT 手动安装）"
echo "  2. 以后重启服务: ssh $TARGET 'bash $REMOTE_DIR/restart_all.sh'"
echo "  3. 看日志: ssh $TARGET 'tail -50 $REMOTE_DIR/logs/dsh.log'（应用日志 logs/app.log）"

#!/usr/bin/env bash
# 检查 DSH 插件对接所需环境：JDK 17+ / Maven / curl
set -u

ok=0  # 0=全部通过

if command -v java >/dev/null 2>&1; then
  ver=$(java -version 2>&1 | head -1)
  echo "[OK] java: $ver"
  major=$(java -version 2>&1 | head -1 | sed -E 's/.*"([0-9]+)\..*/\1/')
  if [ "${major:-0}" -lt 17 ]; then
    echo "[FAIL] 需要 JDK 17+，当前主版本 ${major:-unknown}"
    echo "  macOS:  brew install openjdk@17 && sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk"
    echo "  Ubuntu: sudo apt-get update && sudo apt-get install -y openjdk-17-jdk"
    ok=1
  fi
else
  echo "[FAIL] 未找到 java"
  echo "  macOS:  brew install openjdk@17"
  echo "  Ubuntu: sudo apt-get update && sudo apt-get install -y openjdk-17-jdk"
  ok=0
fi

if command -v mvn >/dev/null 2>&1; then
  echo "[OK] maven: $(mvn -version 2>&1 | head -1)"
else
  echo "[WARN] 未找到 mvn（仅运行预构建 jar 时可不需要；开发插件需要）"
  echo "  macOS:  brew install maven"
  echo "  Ubuntu: sudo apt-get update && sudo apt-get install -y maven"
fi

command -v curl >/dev/null 2>&1 && echo "[OK] curl: $(curl --version | head -1 | cut -d' ' -f1-2)" || { echo "[FAIL] 未找到 curl"; ok=0; }

exit $ok

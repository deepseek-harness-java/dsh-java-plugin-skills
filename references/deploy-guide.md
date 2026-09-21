# DSH Java 部署指南

## 前置环境

- 运行 DSH 或应用：JDK 17+（无 Maven 也可以，直接 `java -jar`）
- 开发插件：JDK 17+ + Maven 3.6+
- 检查：`bash <skill_path>/scripts/check_env.sh`

缺失时安装：
- macOS：`brew install openjdk@17`（如需：`sudo ln -sfn "$(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-17.jdk`）、`brew install maven`
- Ubuntu/Debian：`sudo apt-get update && sudo apt-get install -y openjdk-17-jdk maven`
- CentOS/RHEL：`sudo yum install -y java-17-openjdk java-17-openjdk-devel maven`

## 启动 DSH Harness

### 方式一：技能内置 JAR（最快）

```bash
bash <skill_path>/scripts/start_harness.sh
# 或手动：java -jar <skill_path>/runtime/deepseek-harness-java-app.jar
```

地址：http://127.0.0.1:8090 。首次使用需在「设置 → 模型设置 → 添加模型」配置模型服务地址、模型名称和 API Key，否则无法对话。

### 方式二：Docker（服务器推荐）

```bash
docker run -d --name dsh-java-web -p 8090:8090 \
  registry.cn-hangzhou.aliyuncs.com/xfg-studio/deepseek-harness-java:0.1.6.4
# 注入模型凭据：加 -e DEEPSEEK_API_KEY='your-key'
```

### 方式三：标准部署脚本（Harness + 商城组合）

```bash
curl -fsSLO https://dsh-java.xiaofuge.cn/scripts/deploy-standard.sh
chmod +x deploy-standard.sh && ./deploy-standard.sh
```

## 启动业务应用

Spring Boot 应用：`java -jar xxx-app/target/xxx-app-*.jar`（或 `mvn spring-boot:run -pl xxx-app`）。案例端口：商城 18080、MySQL 平台 8091。

## 部署到远程服务器（推荐用一键脚本）

### 方式一：一键部署脚本（首选）

```bash
bash <skill_path>/scripts/deploy_remote.sh -t root@<服务器IP> \
  -a xxx-app/target/xxx-app-*.jar \
  -g xxx-plugin/target/xxx-plugin-*.jar \
  [-s skip]   # 服务器上已有 DSH JAR 时跳过上传（首次部署不加）
```

脚本自动完成：SSH 连通性检查 → 上传 JAR 到 `/opt/dsh/` → 生成远端重启脚本 `restart_all.sh`（显式 `--server.port`，防 SERVER_PORT 环境变量劫持）→ 启动 → 探活 → 输出重启/日志/插件激活指引。

### 方式二：手工部署（脚本不可用时）

1. 上传宿主 JAR、应用 JAR、插件 JAR 到服务器（如 `/opt/dsh/`）
2. 服务器上：`nohup java -jar /opt/dsh/deepseek-harness-java-app.jar --server.port=8090 > /opt/dsh/logs/dsh.log 2>&1 &`，同法启动应用（务必显式 `--server.port`）
3. 防火墙/安全组放行 8090 与应用端口
4. 交付地址时使用服务器公网 IP/域名

### 云部署注意事项

- 插件需在远端 DSH 重新 install+activate（本地插件状态不会跟着 JAR 过去）
- 交付后全部验证项（逐工具实测/UI/探活）必须在远端地址重跑，本地验证通过 ≠ 远端可用
- 生命周期说明要给远端重启命令：`ssh <host> 'bash /opt/dsh/restart_all.sh'`

## 交付清单（每次部署完成后必须给用户）

- DSH 控制台：`http://<host>:8090`（提醒配置模型）
- 应用地址：`http://<host>:<port>`
- 插件状态与工具清单（`curl $HARNESS/api/harness/plugins`）
- 使用方法：打开 DSH → 配置模型 → 对话触发插件工具；应用页面 AI 入口走 DSH `/api/agent/stream`

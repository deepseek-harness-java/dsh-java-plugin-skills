# 运行环境坑位与端到端验证指南

> 来源：personal-ledger（青苔记账）案例全流程实战沉淀。凡是在 AI 沙箱 /受限代理环境 里跑 DSH 对接任务，先读本篇，能省掉大半调试时间。

## 一、沙箱 / 受限环境四大坑（最高频，先看这里）

### 1. `SERVER_PORT` 环境变量劫持端口（必踩）

沙箱会向进程注入 `SERVER_PORT=<随机端口>` 环境变量，Spring Boot relaxed binding 会**直接吃掉它，优先级高于 application.yml**——你配了 `server.port: 18081` 也没用，应用会绑到随机端口（如 57067）。

**修复**：命令行参数优先级最高，启动时必须显式传：

```bash
java -jar app.jar --server.port=18081   # ✅ 正确
java -jar app.jar                        # ❌ 会被 SERVER_PORT 环境变量劫持
```

**排查方法**：启动后 `lsof -nP -iTCP -sTCP:LISTEN | grep java` 看实际监听端口；若与预期不符，用 `ps eww <pid> | tr ' ' '\n' | grep -i server_port` 验证注入。

### 2. `HTTP_PROXY` 导致 curl 本机 502（必踩）

环境里常驻 `HTTP_PROXY=http://127.0.0.1:<port>` 代理，curl 访问 `127.0.0.1:8090` 会被转发到代理，返回 **502**——看起来像服务挂了，其实服务好好活着。

**修复**：所有本机 curl 统一带：

```bash
curl --noproxy '*' ...          # 单条命令
# 或会话级：
export no_proxy='127.0.0.1,localhost' NO_PROXY='127.0.0.1,localhost'
```

**判别口诀**：本机 curl 502/000 ≠ 服务挂了，先 `lsof -nP -iTCP:<port> -sTCP:LISTEN` 确认监听再下结论。

### 3. nohup / 脚本子进程会被会话回收

用 `nohup java -jar ... &` 或在一次性脚本里启动的服务，**脚本/会话结束后进程即被回收**，用户下次访问时服务已死。

**修复**：
- 在 AI Agent 环境里用**受管后台任务**（如 run_in_background）启动长驻服务；
- 每轮交付/回访前先探测：`lsof -nP -iTCP:18081 -sTCP:LISTEN`，进程没了就重新拉起再交付。

### 4. 端口探测必须"实际探活"而不是猜

启动脚本说监听 8090 不代表真的 8090（见坑 1），日志说了不算，用探活循环确认：

```bash
for i in $(seq 1 30); do
  curl -s --noproxy '*' -o /dev/null --max-time 2 http://127.0.0.1:$PORT/ && { echo UP; break; }
  sleep 1
done
```

## 二、DSH 运行时已验证事实（不用再试错）

| 事实 | 说明 |
|---|---|
| **agentId 按需创建** | DSH 用 `agentFactory.create(agentId, ...)` 懒加载，**任意 agentId 直接可用**（如 `customer-service-demo`），无需预置 agent 或建 workspace |
| **runtime jar 已带默认模型渠道** | 技能包 `runtime/deepseek-harness-java-app.jar` 内置 custom 渠道，启动后即可直接跑 `/api/agent/stream` 端到端测试，不配模型也能通 |
| **SSE 事件名全集** | `meta` → `chunk`（正文增量）→ `reasoning`（思考增量）→ `step_break`（工具调用开始）→ `tool_result`（工具结果）→ `finish` → `done`；异常时 `error`。data 均为 JSON |
| **并行工具调用** | Agent 支持一次并行调多个工具（实测 expense_summary + budget_status 并行） |
| **工具名暴露格式** | Agent 侧为 `plugin__<pluginId>__<toolName>`，step_break/tool_result 事件里 `toolName` 字段可确认实际调用 |
| **内存数据重启即还原** | 预置数据用内存 Map 时，写操作测完重启应用即还原种子数据，无需回滚脚本 |

## 三、端到端验证配方（标准动作，按顺序做）

### 1. 应用 API 数据正确性（算术一致）

```bash
curl -s --noproxy '*' "http://127.0.0.1:18081/api/xxx/summary?month=2026-09"
# 核对：汇总值 = 明细逐条加总（python 一行即可），笔数、分类占比一致
```

### 2. 写操作实测 + 还原

```bash
curl -s --noproxy '*' -X POST http://127.0.0.1:18081/api/xxx/实体 -H 'Content-Type: application/json' -d '{...}'
# 再查 summary 确认联动 → 重启应用还原种子数据
```

### 3. DSH Agent 端到端（直接看工具调用）

```bash
bash <skill_path>/scripts/agent_stream.sh [host:port] [agentId] "自然语言问题"
# 输出三段：工具调用轨迹（step_break/tool_result）+ 最终中文回答
```

**验收标准**：① 工具确实被调用（不是模型瞎编）；② 回答中的数字与工具返回数据一致；③ 超支/异常场景能给出结论。

### 4. 应用侧 AI 代理链路

应用前端 AI 面板走 `POST /api/assistant/stream`（SSE 代理到 DSH），同样用 curl 灌一条消息验证流式输出非空。

## 四、提效经验

1. **先读参考案例源码，不要凭记忆写 API**：`AbstractTool` 的准确签名（`required(String...)`、`ok()/fail()`）在 `deepseek-harness-java-types` 源码里，5 分钟确认胜过编译报错半小时。
2. **Maven 依赖提前探测**：构建前 `ls ~/.m2/repository/cn/xiaofuge/` 确认 `deepseek-harness-java-types` 已在本地（0.1.5），避免网络拉取失败。
3. **构建一次通过的要素**：严格照 `plugin-dev-guide.md` 的骨架（provided scope、plugin.yaml、SPI 文件三件套一个不能少），`mvn package -DskipTests -q` 即可。
4. **开发顺序**：后端实体→Store→Controller → 前端三件套 → 插件五件套（ApiClient/AbstractTool/工具类/Plugin主类/yaml+SPI）→ 构建 → 起服务 → 装插件 → 端到端，每步有产物确认，不回头。

# 案例二：dsh-java-mysql（MySQL 运维平台）

仓库：https://github.com/fuzhengwei/dsh-java-mysql

独立 MySQL 轻量管理后台（MySQL Studio），附带 DSH 只读插件，让 Agent 安全查询/分析数据库。

## 结构

- `dsh-java-mysql-app`：Spring Boot 管理后台（Admin UI + Admin API），端口 8091
- `dsh-java-mysql-plugin`：Harness 只读 MySQL 插件（JAVA_NATIVE），pluginId = `dsh-java-mysql-plugin`

## 架构特点（安全边界设计典范）

```text
浏览器 ──► Admin UI (8091) ──► Admin API ──► MySQL
              │
              └─ AI 对话 ──► deepseek-harness-java (8090)
                                └─ dsh-java-mysql-plugin ──► Admin API ──► MySQL
```

-插件不持有 MySQL 密码**，统一走 Admin API
- **AI 链路全程只读**：只注册只读/EXPLAIN/性能/规则审计工具；服务端二次校验，非只读且无 allowWrite 直接拒绝
- 页面写 SQL 需勾选 + 人工二次确认
- 连接密码本机 AES-256-GCM 加密存储（`~/.dsh-java-mysql/connections.json`）

## 插件工具

| 工具 | 说明 |
| --- | --- |
| `mysql_list_connections` | 列出已配置连接（上下文已有 connectionId 时不要调用） |
| `mysql_read_query` | 只读查询 SELECT/SHOW/DESC，必须查证真实结果 |
| `mysql_explain_query` | EXPLAIN 执行计划 |
| `mysql_performance_snapshot` | 连接数/慢查询/锁等待快照 |
| `mysql_sql_review` | 本地规则 SQL 风险审计（不连库） |

系统提示词强制"禁止生成/执行 UPDATE/ALTER/CREATE/TRUNCATE"，PRE_TOOL_USE 审计所有 mysql_ 工具调用。

## 启动与安装

```bash
mvn package -DskipTests
java -jar dsh-java-mysql-app/target/*.jar    # http://127.0.0.1:8091，先添加数据库连接
# 插件 JAR: dsh-java-mysql-plugin/target/dsh-java-mysql-plugin-0.1.0-SNAPSHOT.jar
# install_plugin.sh 安装激活；插件配置 adminBaseUrl 可覆盖默认 http://127.0.0.1:8091
```

## 适用作为"工具型插件"模板：把一个已有系统的管理 API 封装成只读工具集，配系统提示词边界 + Hook 审计 + 服务端二次校验。

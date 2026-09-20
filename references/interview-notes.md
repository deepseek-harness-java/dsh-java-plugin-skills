# DSH Java 插件对接 — 面试资料

## 一句话介绍

我基于 deepseek-harness-java（一个 Java Agent 运行时基座）实现过完整的智能体应用对接：为业务系统开发 Java Native 插件，把业务 API 注册成 Agent 可调用的工具，通过 SPI + plugin.yaml 动态装载，支持 PRE/POST_TOOL_USE Hook 审计，实现"AI 自然语言驱动LM API 的区别？
直接调 API = 单轮问答；Harness = 运行时基座，负责会话编排、工具（Function Calling）分发、流式输出、插件生命周期、Hook 机制、模型接入配置。业务只写工具，不关心编排。

### 2. 你的插件机制怎么设计的？为什么不把工具写死在宿主里？
- Java Native Plugin：JAR + SPI（`META-INF/services/JavaHarnessPlugin`）+ `plugin.yaml` 元数据
- 宿主类加载器加载插件 JAR，实例化主类（`AbstractHarnessPlugin`），`tools()` 返回 `ToolDefinition` 列表，运行时以 `plugin__<pluginId>__<tool>` 命名空间暴露给模型
- 好处：热插拔（install/activate 接口/界面上传）、业务解耦、依赖隔离（插件依赖 provided，宿主统一提供 types）

### 3. 工具调用的安全怎么保证？
- 插件不持有敏感凭据，统一走业务应用 Admin API（HTTP），应用侧鉴权（service-token）
- 只读边界：系统提示词约束 + 服务端强制校验（如 MySQL 案例拒绝非只读 SQL，无 allowWrite 直接拒绝）
- Hook 审计：PRE_TOOL_USE 记录调用上下文，POST_TOOL_USE 事件审计
- 写操作必须人工页面确认，AI 链路不可写

### 4. 工具的 description 为什么重要？
LLM 靠 description 决定何时调用哪个工具。要写清：何时必须调用（查证真实结果禁止编造）、何时不要调用（上下文已有 ID）、返回什么、参数含义。错误/模糊的 description 直接导致误调用或漏调用。

### 5. 插件如何调用业务系统？配置怎么管理？
工具 run() 内用 JDK HttpClient 调业务 REST API，带连接超时、非 2xx 异常兜底返回 JSON error。可配置项（base-url、service-token）放插件配置，`configure(PluginContext)` 读取；修改配置需停用再启用插件重新 configure。

### 6. 说说你做过的一个具体对接（STAR）
- S：商城需要 AI 客服能查商品/订单/物流
- T：不改动商城核心逻辑，接入 Agent 能力
- A：商城暴露 REST API；开发 mall-weekend-assistant 插件注册 5 个工具；页面 AI 面板代理 DSH `/api/agent/stream`（SSE）；service-token 双向校验；POST_TOOL_USE 审计
- R：用户在商城页面自然语言完成售前咨询与订单查询，AI 全程只能读不能写

### 7. 流式输出怎么实现的？
`/api/agent/stream` SSE：思考过程 → 工具调用事件 → 最终答案分段推送；前端 EventSource/代理透传即可。

## 可展示的量化点

- 2 个完整案例：智能客服（5 工具）、MySQL 只读运维（5 工具）
- 安装即用：一条 curl（install+activate）或界面上传 JAR 完成接入
- 安全：AI 链路 100% 只读、Hook 全量审计、凭据零下发

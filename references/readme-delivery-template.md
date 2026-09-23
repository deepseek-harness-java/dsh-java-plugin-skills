# README 交付模板与简历/面试沉淀模板

> 每个项目开发完成后**必做**：按本模板产出工程 README。它同时是项目说明、用户体验指南和求职沉淀材料，一次写好三处复用。

## 一、README 模板（照此结构写，内容必须真实来自已验证的项目）

```markdown
# <项目中文名> · <英文名>（<一句话定位>）

基于 `dsh-java-plugin-skills` 技能流程生成：<业务应用> + DeepSeek Harness AI <XX助手>插件。

## 一句话需求
> <用户当时选定的/给出的原始需求原文>

## 使用说明
- **这是什么**：<一句话说明业务定位与 AI 能力>
- **你能做什么**：<浏览/查询/下单/操作等核心能力>
- **怎么用**：<打开应用、登录、触发 AI、到 DSH 验证>
- **适合谁**：<体验者/学习者/面试官/业务方>

## 快捷体验流程
1. 打开应用：<真实地址> → 登录演示账号
2. 触发 AI：右下角浮按钮 → 示例问题：<实测问题>
3. 验证结果：确认回答中的数字/状态来自工具返回
4. 进阶体验：DSH 控制台 → 同一 Agent → 示例问题

## 服务地址（交付前逐一探活确认过才写进这里）
| 服务 | 地址 | 说明 |
| --- | --- | --- |
| <应用名> | http://127.0.0.1:<port> | 业务主界面 + AI <XX>助手面板 |
| DSH 控制台 | http://127.0.0.1:8090 | Agent 对话、插件管理（默认模型渠道已配置） |

## 插件信息
- pluginId：`<id>`（JAVA_NATIVE，ACTIVE）
- 入口类：`<全限定名>`
- 插件配置：`<base-url 配置项>`、`<service-token 配置项>`（修改后需停用再启用插件）

## 工具清单（Agent 中以 `plugin__<pluginId>__<tool>` 暴露）
| 工具 | 类型 | 说明 |
| --- | --- | --- |
| `xxx` | 读 | <一句话，写清返回什么> |
| `xxx` | **写** | <写操作必须标注 isConcurrencySafe 与确认要求> |

## 体验流程说明（给使用者，按步骤照做就能体验到完整闭环）
1. **打开应用**：<url> → 能看到什么（主界面核心区块逐个点名）
2. **触发 AI**：右下角浮按钮 → 侧滑面板 → 示例问题逐条列出（每个示例注明会触发哪个工具）
3. **DSH 控制台体验**：<url> → 对话框直接输入自然语言 → 示例问题（注明触发的工具名）
4. **写操作体验**：示例话术（AI 会先与你确认金额/参数再执行）

## 预置数据（细腻度规范）
- <数据量、字段完整性、数据故事、算术一致性说明>

## 构建与启动
mvn package -DskipTests
java -jar xxx-app/target/xxx-app-<ver>.jar --server.port=<port>
bash <skill_path>/scripts/install_plugin.sh <jar> <pluginId> <版本> <入口Jar文件名> "<显示名>"

## 环境坑位记录（本机实测）
<把本次遇到的真实坑写进来，供复现者参考>
```

**README 质量红线**：服务地址必须是**交付前刚探活确认（HTTP 200）**的地址，禁止照抄历史值；示例问题必须**实测触发过对应工具**；预置数据描述必须与实际代码一致。

**截图质量红线**：README 中的截图不得互相重复；至少包含一张真实 AI 对话截图（能看到用户问题、模型回答或工具结果卡片）；不要用空白面板或同一页面的重复截图凑数。

## 二、简历项目模板（STAR 压缩到 3~5 行，可直接粘贴）

```markdown
**<项目名>（<年份>）** — 个人全栈项目 | 技术栈：<Java 17 / Spring Boot 3.x / Maven 多模块 / 原生前端>
- 基于 Java Agent 运行时基座（DeepSeek Harness），以 **Java Native Plugin（SPI + 类加载隔离）** 方式为业务应用扩展 AI 能力，注册 <N> 个 Agent 工具（读 <M> 写 <K>），由 LLM 按语义自主编排调用
- 设计 <核心机制亮点，如：插件-应用 HTTP 边界 + service-token 鉴权 + PRE/POST 工具审计 Hook + 写操作人工确认>，兼顾能力开放与安全边界
- 实现 SSE 流式对话（<事件协议>）、内存种子数据算术一致、端到端自动化验证脚本；<一个具体的业务成果，如：AI 准确识别购物超支 214.9% 并给出省钱建议>
```

要点：**数字具体**（几个工具、几个模块、什么指标）、**机制写清**（插件怎么接进去的、安全边界在哪）、**避免空话**（"使用了微服务架构"这种没有信息量的句子不要）。

## 三、技术关键词（简历技能栏/检索用，按真实使用情况勾选）

| 层 | 关键词 |
| --- | --- |
| 运行时/语言 | Java 17、Spring Boot 3.x、Maven 多模块、SPI（ServiceLoader）、Java 类加载隔离 |
| AI/Agent | LLM 工具调用（Function Calling）、Agent 工作流、系统提示词工程、工具描述设计、Java Native Plugin、SSE 流式响应、PRE/POST Hook 审计、approvalMode 审批模式 |
| 工程 | REST API 设计、内存数据结构/种子数据设计、前后端分离（原生前端）、端到端验证、插件生命周期（install/activate/deactivate） |
| 安全 | 服务间鉴权（service-token）、最小权限边界（插件不直连敏感资源）、写操作确认机制 |

## 四、面试重点（本项目最容易被追问的点 + 答题要点）

1. **插件是怎么被宿主加载的？** → SPI（`META-INF/services` + ServiceLoader）发现入口类 → 宿主独立类加载器加载 fat jar（依赖 scope=provided 避免与宿主冲突）→ `plugin.yaml` 声明元数据 → install/activate 生命周期
2. **Agent 怎么知道有哪些工具、何时调用？** → 插件 `tools()` 返回 `ToolDefinition`（name/description/JSON Schema 参数），以 `plugin__<pluginId>__<toolName>` 注入模型；**description 质量决定调用准确率**，要写清何时必须调、何时不要调
3. **如何防止 AI 乱写数据？** → 写操作工具 description 声明风险 + 系统提示词硬规则（必须与用户确认金额/参数）+ `isConcurrencySafe=false` + approvalMode 审批 + PRE/POST Hook 审计
4. **插件为什么不直连数据库？** → 安全边界：插件只通过业务应用 HTTP API（带 service-token）访问数据，应用保留业务校验与审计的单一入口；插件可独立升级不影响应用
5. **SSE 流式是怎么实现的？** → 服务端 `SseEmitter`，事件名 meta/chunk/reasoning/step_break/tool_result/finish/done/error，data 为 JSON；客户端 fetch 流式解析 `event:`/`data:` 行；心跳保活与超时关闭
6. **如何保证演示数据可信？** → 预置数据有真实品牌/价格区间/数据故事，所有汇总由明细实时计算保证算术一致；交付前用脚本做"汇总=逐条加总"校验
7. **端到端怎么验证 AI 真的调了工具？** → 看 SSE 的 step_break/tool_result 事件里的 toolName 与 result，再核对回答中的数字与工具返回一致（脚本 `agent_stream.sh` 自动化此事）

> 深度追问兜底：`references/interview-notes.md` 有完整面试资料；回答不了的点回到源码确认，不要现场编。

---
name: dsh-java-plugin-skills
description: 辅助用户快速完成 deepseek-harness-java（DSH Java，Java Agent 运行时基座）与业务应用的智能体对接。可以按用户诉求从零开发任意领域的 Java AI 应用（智能客服、MySQL 运维平台、研学旅游、预订平台等）并以 Java Native 插件方式接入 DSH；也可以把用户已有 Java 应用插件化对接 DSH。支持启动/部署 Harness 服务与应用服务、安装激活插件、提供架构图/说明文档/面试资料。触发词：「对接 deepseek-harness-java」「DSH 插件开发」「Java Native Plugin」「智能客服接入」「开发一个 AI 应用」「XX 的 AI 应用/智能体」「插件化对接 Agent」「启动 DSH」「harness 插件安装」。
license: Apache-2.0
metadata:
  author: xfg-studio
  version: "1.0.0"
  category: agent-plugin
  homepage: https://github.com/fuzhengwei/deepseek-harness
---

# DSH Java 插件对接技能

本技能帮助用户**快速完成 deepseek-harness-java（下称 DSH）与业务应用的 AI 智能体对接**。两种典型场景：

1. **用户已有应用** → 为应用开发一个 Java Native 插件，注册工具到 DSH Agent，让 AI 能调用应用能力。
2. **用户没有应用** → 按诉求开发一个 Java 应用（如智能客服商城、MySQL 运维平台），再以插件方式接入 DSH。

最终交付：DSH 服务地址 + 应用服务地址 + 插件安装完成，并告诉用户怎么用。

## 核心概念（必读）

DSH 是 Java Agent 运行时基座（端口 8090），提供 Web 控制台、Agent 对话、模型配置、插件管理。插件是 **Java Native Plugin**：

- 插件 JAR 依赖 `cn.xiaofuge:deepseek-harness-java-types:0.1.5`（scope=provided，宿主提供）
- 继承 `AbstractHarnessPlugin`，在 `tools()` 中返回 `ToolDefinition` 列表（工具继承 `AbstractTool`，实现 `name/description/parameters/run`）
- 在 `configure(PluginContext)` 中注册系统提示词与 Hook（如 `PRE_TOOL_USE` 审计）
- 必须提供 `META-INF/plugin.yaml`（id/name/version/entrypoint）和 SPI 声明文件 `META-INF/services/cn.xiaofuge.deepseek.harness.domain.spi.JavaHarnessPlugin`
- 工具在 Agent 中以 `plugin__<pluginId>__<toolName>` 命名暴露
- 插件通过 HTTP 调用业务应用 API（不直接持有业务资源据，注意超时/异常分类/脱敏）

**本技能目录下已有现成材料，优先使用，不要凭记忆编造：**
- `runtime/deepseek-harness-java-app.jar` — DSH 宿主可执行 JAR，直接 `java -jar` 启动
- `references/plugin-dev-guide.md` — 插件开发全流程（含完整代码骨架，从两个真实案例提炼）
- `references/deploy-guide.md` — 启动部署指南（本地/服务器/无 Java 环境）
- `references/case-2d-weekend-mall.md` / `references/case-dsh-java-mysql.md` — 两个完整案例
- `references/architecture.md` — 架构图与说明（可导出给用户）
- `references/interview-notes.md` — 面试资料
- `scripts/check_env.sh` — 环境检查（Java/Maven 版本，缺失时提示安装方式）
- `scripts/start_harness.sh` — 启动 DSH（自动检查端口 8090）
- `scripts/install_plugin.sh` — 安装+激活插件（curl 调 install/activate 接口）
- `scripts/smoke_test.sh` — 冒烟验证（检查服务、插件列表）

## 工作流程

### 阶段 0：澄清需求
问清楚（不确定时才问，一次问完）：
- **新开发还是对接已有应用？**（这是第一问，二选一确认）
- 有现成应用 → 要仓库地址/路径 + 应用 API 概况
- 新开发 → 明确业务领域与核心场景（如研学旅游：行程/路线/报名/订单；客服：商品/订单/物流），列出该领域 AI 应能查询和操作的核心实体清单
- 运行环境：本地 macOS/Linux 还是远程服务器？有没有 JDK 17+ / Maven？
- DSH 是否已在运行（`curl http://127.0.0.1:8090` 探测）？

**可默认、不必问**（直接采用并在交付时说明）：端口用 18081 起顺延（避开 18080/8091）；数据用内存 Map 预置演示数据（与 2d-weekend-mall 一致，零依赖快速跑通）；前端用原生 HTML/CSS/JS 单页；包名 `cn.xiaofuge.<domain>`。

### 阶段 1：环境准备
```bash
bash <skill_path>/scripts/check_env.sh
```
缺 JDK 17 → 指导 `brew install openjdk@17`（macOS）或 `sudo apt-get install -y openjdk-17-jdk`（Ubuntu）；缺 Maven → `brew install maven` / `sudo apt-get install -y maven`。无本地环境也可用服务器部署（见 deploy-guide）。

### 阶段 2
```bash
bash <skill_path>/scripts/start_harness.sh
```
启动后打开 `http://127.0.0.1:8090`，「设置 → 模型设置 → 添加模型」配置模型地址/名称/API Key，否则 Agent 无法对话。

### 阶段 3：开发应用与插件
- 无应用：按 `references/plugin-dev-guide.md` 的 Spring Boot 应用骨架 + 插件骨架生成工程（Maven 多模块：`xxx-app` + `xxx-plugin`）
- 有应用：只生成 `xxx-plugin` 模块，工具通过 HTTP 调应用 API
- 遵循两个案例的模式（见 case 文档）：plugin.yaml + SPI + AbstractHarnessPlugin + AbstractTool，提供构建命令 `mvn package -DskipTests`，构建必须亲自执行并确认 JAR 生成

**全新业务应用（任意领域，如研学旅游/预订平台/内容社区）设计范式**（从案例泛化，必须遵守）：
1. **先列实体再设计工具**：从业务场景提取核心实体（如研学旅游 = 营地/路线/排期/报名订单），每个"查询/详情/状态"类实体操作对应一个工具，通常 3~6 个
2. **工具命名动词+宾语**：如 `search_routes`、`route_detail`、`enrollment_query`、`itinerary_query`；只读查询优先，写操作（报名/下单）需在 description 中声明风险
3. **app 模块最小闭环**：REST API（list/detail/create）+ 内存预置数据（8 条左右）+ 单页前端（业务主界面 + AI 助手面板代理 DSH `/api/agent/stream`，参考 case-2d-weekend-mall 模式）
4. **系统提示词划边界**：写明该业务工具何时必须调用（涉及真实数据必须查证）、禁止编造
5. **application.yml 预留**：`harness-base-url`、`agent-id`、`service-token`（与插件配置对应）；改 token 后需停启插件

### 阶段 4：安装插件并交付
```bash
bash <skill_path>/scripts/install_plugin.sh <plugin_jar路径> <pluginId> <版本> <入口Jar文件名>
bash <skill_path>/scripts/smoke_test.sh
```
交付时必须给出：
- DSH 地址：`http://<host>:8090`（配置模型后即可对话）
- 应用地址：`http://<host>:<port>`
- 插件工具清单（`plugin__<pluginId>__<tool>` 形式）与验证方法（在 DSH 对话框直接用自然语言触发工具）
- 「怎么用」说明：登录 DSH 控制台 → 配置模型 → 对话中让 Agent 调用插件工具；应用页面中 AI 入口（若有）代理到 DSH 的 `/api/agent/stream`

### 阶段 5：附加资料（按需）
用户要架构图 → `references/architecture.md`（含 Mermaid，可直接渲染或转图）；要说明文档/面试资料 → 对应 references 文件。

## Gotchas

- 插件依赖 scope 必须 `provided`，否则 fat jar 与宿主类冲突加载失败
- `plugin.yaml` 的 `entrypoint` 是**插件主类全限定名**，而 install 接口的 `entrypoint` 字段是 **JAR 文件名**，两者不同
- install 接口 `sourcePath` 必须是宿主可访问的**绝对路径**
- 修改插件配置（如 mall.service-token）后需停用再启用插件，`configure()` 才会重新执行
- 工具 description 直接影响 Agent 调用准确性：写清「何时必须调用、何时不要调用、返回什么」
- 插件不直连数据库等敏感资源，通过业务应用 Admin API 走 HTTP，守住安全边界
- DSH 未配置模型时对话报错，先检查「设置 → 模型设置」
- 端口约定：DSH 8090；案例应用 18080（商城）/ 8091（MySQL 平台），新应用避开这些端口

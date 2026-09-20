---
name: dsh-java-plugin-skills
description: 辅助用户快速完成 deepseek-harness-java（DSH Java，Java Agent 运行时基座）与业务应用的智能体对接。可以按用户诉求从零开发一个 Java 应用（智能客服、MySQL 运维平台等）并以 Java Native 插件方式接入 DSH；也可以把用户已有 Java 应用插件化对接 DSH。支持启动/部署 Harness 服务与应用服务、安装激活插件、提供架构图/说明文档/面试资料。触发词：「对接 deepseek-harness-java」「DSH 插件开发」「Java Native Plugin」「智能客服接入」「插件化对接 Agent」「启动 DSH」「harness 插件安装」。
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
- 有没有现成应用？有 → 要它仓库地址/路径 + 应用 API 概况；没有 → 要做什么应用（客服/运维/其他）、端口偏好
- 运行环境：本地 macOS/Linux 还是远程服务器？有没有 JDK 17+ / Maven？
- DSH 是否已在运行（`curl http://127.0.0.1:8090` 探测）？

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

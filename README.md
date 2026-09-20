# dsh-java-plugin-skills

AI Agent 技能包：帮助你**快速完成 deepseek-harness-java（DSH，Java Agent 运行时基座）与业务应用的智能体对接**。

支持两种典型场景：

1. **已有应用** → 为应用开发一个 Java Native 插件，注册工具到 DSH Agent，让 AI 能调用应用能力
2. **没有应用** → 按诉求从零开发一个 Java 应用（如智能客服商城、MySQL 运维平台），再以插件方式接入 DSH

最终交付：DSH 服务地址 + 应用服务地址 + 插件安装激活完成，并说明怎么用。

## 目录结构

```
dsh-java-plugin-skills/
├── SKILL.md                          # 技能入口（工作流程、核心概念、Gotchas）
├── scripts/                          # 可执行脚本
│   ├── check_env.sh                  # 环境检查（JDK 17+ / Maven，缺失时提示安装方式）
│   ├── start_harness.sh              # 启动 DSH（自动检查端口 8090）
│   ├── install_plugin.sh             # 安装 + 激活插件（curl 调 install/activate 接口）
│   └── smoke_test.sh                 # 冒烟验证（检查服务、插件列表）
├── runtime/
│   └── deepseek-harness-java-app.jar # DSH 宿主可执行 JAR，直接 java -jar 启动
└── references/                       # 参考文档（渐进式披露，按需加载）
    ├── plugin-dev-guide.md           # 插件开发全流程（含完整代码骨架，从真实案例提炼）
    ├── deploy-guide.md               # 启动部署指南（本地 / 服务器 / 无 Java 环境）
    ├── architecture.md               # 架构图与说明（含 Mermaid，可直接渲染或转图）
    ├── case-2d-weekend-mall.md       # 案例：智能客服商城（端口 18080）
    ├── case-dsh-java-mysql.md        # 案例：MySQL 运维平台（端口 8091）
    └── interview-notes.md            # 面试资料
```

## 快速开始

```bash
# 1. 环境检查（JDK 17+ / Maven）
bash scripts/check_env.sh

# 2. 启动 DSH（默认端口 8090）
bash scripts/start_harness.sh

# 3. 开发应用与插件（参考 references/plugin-dev-guide.md）
#    Maven 多模块：xxx-app + xxx-plugin，mvn package -DskipTests 构建

# 4. 安装并激活插件，冒烟验证
bash scripts/install_plugin.sh <plugin_jar路径> <pluginId> <版本> <入口Jar文件名>
bash scripts/smoke_test.sh
```

启动后打开 `http://127.0.0.1:8090`，「设置 → 模型设置 → 添加模型」配置模型地址/名称/API Key，否则 Agent 无法对话。

## 核心概念

DSH 是 Java Agent 运行时基座（端口 8090），提供 Web 控制台、Agent 对话、模型配置、插件管理。插件是 **Java Native Plugin**：

- 插件 JAR 依赖 `cn.xiaofuge:deepseek-harness-java-types:0.1.5`（scope=**provided**，宿主提供）
- 继承 `AbstractHarnessPlugin`，在 `tools()` 中返回 `ToolDefinition` 列表（工具继承 `AbstractTool`，实现 `name/description/parameters/run`）
- 在 `configure(PluginContext)` 中注册系统提示词与 Hook（如 `PRE_TOOL_USE` 审计）
- 必须提供 `META-INF/plugin.yaml`（id/name/version/entrypoint）和 SPI 声明文件 `META-INF/services/cn.xiaofuge.deepseek.harness.domain.spi.JavaHarnessPlugin`
- 工具在 Agent 中以 `plugin__<pluginId>__<toolName>` 命名暴露
- 插件通过 HTTP 调用业务应用 API（不直接持有业务资源，注意超时/异常分类/脱敏）

## 关键 Gotchas

- 插件依赖 scope 必须 `provided`，否则 fat jar 与宿主类冲突加载失败
- `plugin.yaml` 的 `entrypoint` 是**插件主类全限定名**，而 install 接口的 `entrypoint` 字段是 **JAR 文件名**，两者不同
- install 接口 `sourcePath` 必须是宿主可访问的**绝对路径**
- 修改插件配置（如 mall.service-token）后需停用再启用插件，`configure()` 才会重新执行
- 工具 description 直接影响 Agent 调用准确性：写清「何时必须调用、何时不要调用、返回什么」
- 插件不直连数据库等敏感资源，通过业务应用 Admin API 走 HTTP，守住安全边界
- DSH 未配置模型时对话报错，先检查「设置 → 模型设置」
- 端口约定：DSH 8090；案例应用 18080（商城）/ 8091（MySQL 平台），新应用避开这些端口

## 安装技能

```bash
# Claude Code
cp -r dsh-java-plugin-skills ~/.claude/skills/

# OpenClaw
cp -r dsh-java-plugin-skills ~/.qclaw/skills/

# OpenAI Codex
cp -r dsh-java-plugin-skills ~/.codex/skills/
```

## 许可证

Apache-2.0

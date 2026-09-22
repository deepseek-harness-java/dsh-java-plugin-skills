# dsh-java-plugin-skills

AI Agent 技能包：帮助你**快速完成 deepseek-harness-java（DSH，Java Agent 运行时基座）与业务应用的智能体对接**。

支持两种典型场景：

1. **已有应用** → 为应用开发一个 Java Native 插件，注册工具到 DSH Agent，让 AI 能调用应用能力
2. **没有应用** → 按诉求从零开发一个 Java 应用（业务系统 + 内嵌 AI 助手 + DSH 插件），再以插件方式接入 DSH

最终交付：**探活确认可访问的** DSH 地址 + 应用地址 + 插件安装激活完成 + 体验流程说明 + 完善的工程 README（含简历/面试沉淀），每个插件工具全链路实测通过。

## 它能做出什么项目

### 三种交付形态

| 形态 | 产出 | 适合 |
|---|---|---|
| **应用 + DSH 插件** | `xxx-app`（业务应用）+ `xxx-plugin`（插件），AI 在 DSH 对话中能查数据、做操作 | 标准玩法，AI 智能体全链路 |
| **仅独立应用** | 只生成 `xxx-app`，功能照常能用，与 DSH 无关 | 只要业务系统本身 |
| **先设计 + 原型** | 实体表、工具清单、页面原型，确认后再开发 | 想先对齐方向 |

### 27 个开箱即用案例（覆盖 20 个领域分类）

对助手说一句案例编号或名称（如「就做 P23」），即可一句话完成开发、部署、启动：

```
商城零售   P1 数码商城 · P2 生鲜团购        新闻资讯   P22 财经早报
金融信贷   P3 记账助手 · P4 信贷模拟器      智能硬件   P23 家居中控
出行配送   P5 出行规划 · P6 外卖订餐        创作工具   P24 自媒体工作台
生活服务   P7 探店点评                     农业乡村   P25 智慧农场
项目协作   P8 团队看板                     环保公益   P26 碳普惠
营销增长   P9 活动工厂                     科技前沿   P27 AI 监控台
社交社区   P10 兴趣广场
医疗健康   P11 在线问诊 · P12 健身私教
教育学习   P13 在线课程 · P14 单词背诵
咨询服务   P15 IT 工单
政务公共   P16 办事大厅
内容文旅   P17 研学旅游 · P18 阅读笔记
工具效率   P19 会议纪要 · P20 订阅管理
娱乐内容   P21 音乐歌单
```

**精选案例长什么样**（每个应用 = 业务主界面 + 右下角 AI 助手面板 + 3~6 个 Agent 工具）：

| 案例 | 应用形态 | AI 能力亮点 |
|---|---|---|
| P1 数码商城 | 商品网格 + 购物车 + 订单物流 | 跨「商品/订单/物流」多工具联动：对比推荐、订单追踪一句话完成 |
| P6 外卖订餐 | 餐厅卡片 + 菜单 + 骑手位置模拟 | 按口味跨餐厅推荐、凑单建议、写操作下单前先复述确认 |
| P11 在线问诊 | 科室导航 + 排班日历 + 病历卡 | 症状→科室推荐、病史结构化摘要（只导诊不诊断，带免责声明） |
| P17 研学旅游 | 路线卡片 + 行程时间线 + 报名 | 按孩子年龄兴趣推荐路线、查排期余位、逐日行程解答 |
| P22 财经早报 | 要闻时间轴 + 板块行情条 | 跨分类聚类要闻、每日早报一键生成、解读新闻影响的板块 |
| P23 家居中控 | 房间分区设备卡 + 能耗图表 | 读传感器数据做联动决策：「卧室太干」→查湿度→生成睡前场景 |
| P27 AI 监控台 | 服务健康总览 + 成本看板 | 告警根因解读、成本翻倍定位异常服务——贴近 DSH 自身运维场景 |

**案例库之外的领域**：按「Prompt 结构公式」即时生成同结构案例（业务实体 + AI 工具 + 前端 + AI 助手），同样一句话可执行——这套技能不挑领域。

### 已落地的完整案例

| 案例 | 位置 | 说明 |
|---|---|---|
| 2D Weekend Mall 智能客服商城 | `references/case-2d-weekend-mall.md` | 旗舰标杆：商品/订单/物流 5 工具，端口 18080 |
| MySQL 运维平台 | `references/case-dsh-java-mysql.md` | 管理后台型：库表巡检/慢 SQL 分析，端口 8091 |
| 外卖订餐平台 | 实战交付案例 | 5 工具全链路实测，沉淀 8 条环境坑位（SERVER_PORT 劫持、插件热更新等） |

## 工作流程（六阶段）

```
阶段 0 澄清需求   → 已有应用 or 新项目？交付形态三选一（可从 27 案例菜单选）
阶段 1 环境准备   → check_env.sh，缺 JDK 17/Maven 给安装指引
阶段 2 启动 DSH   → start_harness.sh，8090 控制台配模型
阶段 3 开发应用   → 场景深挖（实体表→工具表→页面→预置数据）→ 设计稿确认 → 写码
阶段 4 验证交付   → install_plugin.sh → 逐工具 agent_stream.sh 实测 → delivery_check.sh → 真实浏览器 UI 验证
阶段 5 文档沉淀   → 工程 README + 简历 STAR 模板 + 技术关键词 + 面试重点
阶段 6 验收迭代   → 索要验收反馈，小改轻回归 / 大改全流程，跨会话断点续作
```

## 目录结构

```
dsh-java-plugin-skills/
├── SKILL.md                          # 技能入口（工作流程、核心概念、Gotchas）
├── scripts/                          # 可执行脚本
│   ├── check_env.sh                  # 环境检查（JDK 17+ / Maven，缺失时提示安装方式）
│   ├── start_harness.sh              # 启动 DSH（端口探测 + 防 SERVER_PORT 劫持/代理 502）
│   ├── install_plugin.sh             # 安装 + 激活插件（curl 调 install/activate 接口）
│   ├── smoke_test.sh                 # 冒烟验证（检查服务、插件列表）
│   ├── agent_stream.sh               # Agent 端到端流式调用（工具轨迹 + 最终回答，交付前必用）
│   ├── delivery_check.sh             # 最终交付自动化检查（探活/插件状态/鉴权回归）
│   └── deploy_remote.sh              # 云服务器一键部署（上传 JAR → 远端重启脚本 → 探活）
├── runtime/
│   └── deepseek-harness-java-app.jar # DSH 宿主可执行 JAR（已带默认模型渠道，可直接端到端验证）
└── references/                       # 参考文档（渐进式披露，按需加载）
    ├── plugin-dev-guide.md           # 插件开发全流程（含完整代码骨架，从真实案例提炼）
    ├── ui-design-guide.md            # UI 设计指南（design tokens、无 AI 味清单、AI 面板规范、md 渲染）
    ├── prompt-recipes.md             # 27 案例储备库 + 场景深挖卡片 + 细腻度规范
    ├── runtime-pitfalls.md           # 运行环境坑位与端到端验证指南
    ├── delivery-checklist.md         # 最终交付清单（自动化项 + 手工项 + 回归矩阵）
    ├── readme-delivery-template.md   # README 交付模板 + 简历项目模板
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

# 5. 交付前：逐工具端到端实测 + 交付检查
bash scripts/agent_stream.sh
bash scripts/delivery_check.sh <pluginId>
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

架构：**DSH Agent（8090）→ 插件（对接器）→ 业务应用（HTTP）**，Mermaid 图见 `references/architecture.md`。

## 关键 Gotchas

- 插件依赖 scope 必须 `provided`，否则 fat jar 与宿主类冲突加载失败
- `plugin.yaml` 的 `entrypoint` 是**插件主类全限定名**，而 install 接口的 `entrypoint` 字段是 **JAR 文件名**，两者不同
- install 接口 `sourcePath` 必须是宿主可访问的**绝对路径**
- 修改插件配置（如 mall.service-token）后需停用再启用插件，`configure()` 才会重新执行
- 工具 description 直接影响 Agent 调用准确性：写清「何时必须调用、何时不要调用、返回什么」
- 插件不直连数据库等敏感资源，通过业务应用 Admin API 走 HTTP，守住安全边界
- DSH 未配置模型时对话报错，先检查「设置 → 模型设置」
- 端口约定：DSH 8090；案例应用 18080（商城）/ 8091（MySQL 平台），新应用 18081 起顺延
- 沙箱/受限代理环境的 SERVER_PORT 劫持、HTTP_PROXY 502、进程回收等坑，见 `references/runtime-pitfalls.md`
- 生成前端时 AI 气泡必须做 markdown 渲染（`renderMd` 渲染器见 `references/ui-design-guide.md` 第五节），禁止 `textContent` 裸显模型回复

## 安装技能

```bash
# WorkBuddy
cp -r dsh-java-plugin-skills ~/.workbuddy/skills/

# Claude Code
cp -r dsh-java-plugin-skills ~/.claude/skills/

# OpenClaw
cp -r dsh-java-plugin-skills ~/.qclaw/skills/

# OpenAI Codex
cp -r dsh-java-plugin-skills ~/.codex/skills/
```

## 许可证

Apache-2.0

# 应用 UI 设计指南（无 AI 味）

目标：生成的每个应用界面都像**认真做过的产品**，而不是"AI 生成的 demo 页"。本指南从 2d-weekend-mall 真实前端（`mall-app/src/main/resources/static/`）与社区优质实践（50projects50days、SpinKit 等）提炼，生成前端时**必须遵守**。

## 一、先定调，再写码（Design Tokens）

写任何 HTML 前先确定 tokens，全部用 CSS 变量集中管理：

```css
:root {
  /* 1. 配色：一个主色 + 一个强调色 + 中性色阶。禁止默认蓝紫渐变 (#6366f1/#8b5cf6) */
  --bg: #f7f5ef;            /* 页面底色：暖白/奶油，不用纯白 #fff */
  --card: #fffdf8;          /* 卡片底 */
  --ink: #22302f;           /* 正文：深墨绿/炭黑，不用纯黑 */
  --muted: #71807b;         /* 次要文字 */
  --primary: #0e847a;       /* 主色：按领域选（文旅=青绿，医疗=蓝绿，餐饮=橘红，工具=石墨蓝） */
  --accent: #f4693d;        /* 强调色：仅用于徽标/角标/强调，占比 <10% */
  --line: rgba(34,48,47,.09);
  --shadow: 0 22px 60px rgba(46,74,68,.12);

  /* 2. 圆角：大圆角是"产品感"的关键，别用 4px/8px 的小工程师圆角 */
  --r-sm: 12px; --r-md: 20px; --r-lg: 28px; --r-pill: 999px;

  /* 3. 字体栈：系统字体优先，中文必须带 PingFang SC / Microsoft YaHei */
  --font: -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif;
}
```

**选主色的思路**：从业务联想到颜色——文旅/研学→青绿+暖橙、健康→薄荷绿、金融→深墨绿、餐饮→橘红、儿童→明黄。避开 AI 味最重的两个信号：默认紫、默认蓝紫渐变。

## 二、"无 AI 味"的核心手法

1. **有层次的背景**：纯色背景 = demo 感。用「径向渐变光斑 + 细点阵纹理」：

```css
.page-bg {
  position: fixed; z-index: -2; inset: 0;
  background: radial-gradient(circle at 78% 0, #d9f3e8 0, transparent 34%),
              radial-gradient(circle at 8% 28%, #ffeeda 0, transparent 28%),
              linear-gradient(180deg, #fffdf8, var(--bg) 54%);
}
/* 细点阵，让背景有"材质" */
.page-bg::after {
  content: ""; position: fixed; z-index: -1; inset: 0;
  background-image: radial-gradient(rgba(14,132,122,.12) 1px, transparent 1px);
  background-size: 22px 22px; opacity: .28;
}
```

2. **Hero 区有排版张力**：大标题 `clamp(40px, 6vw, 72px)` + 负字距（`letter-spacing: -2px`）+ 一个彩色强调词（`<em>`）；小标签用大写字距 eyebrow（`letter-spacing: 3px; text-transform: uppercase; font-size: 12px`）
3. **卡片悬浮反馈**：hover 上浮 + 阴影加深（`translateY(-6px)`），transition 0.25s
4. **胶囊按钮**：`border-radius: var(--r-pill)`，主按钮带品牌色渐变 + 彩色投影（`box-shadow: 0 14px 30px rgba(primary,.22)`），hover 上浮 2px
5. **毛玻璃吸顶导航**：`position: sticky; backdrop-filter: blur(20px); background: rgba(card,.88); border-bottom: 1px solid var(--line)`
6. **数字有分量**：统计数字 26px+ 加粗，标签 13px muted，形成对比

## 三、AI 味清单（出现任何一条即为不合格，必须重写）

| AI 味信号 | 正确做法 |
| --- | --- |
| 默认蓝紫渐变 hero、`linear-gradient(135deg,#667eea,#764ba2)` | 按领域选主色，渐变仅用于主按钮/品牌标 |
| 纯白背景 + 居中一列卡片 | 渐变光斑背景 + 非对称布局（hero 左文右卡） |
| 所有圆角 8px、所有阴影 0 2px 4px | 大圆角 20~34px、多层大投影 |
| Inter 字体 + 全英文占位（Lorem ipsum） | 系统字体栈 + 真实中文业务文案 |
| emoji 当图标（🛒🚀✨） | 内联 SVG 图标（线性，1.5~2px stroke，`currentColor`） |
| 表格裸奔、灰色边框直角框 | 卡片式数据展示 + 斑马纹/悬浮高亮 |
| 按钮无 hover/无过渡、无加载态 | 所有交互元素有 transition + loading 态 |
| 三等分"feature 卡片"阵列（Why choose us x3） | 真实业务区块：列表/详情/表单/状态，信息密度有变化 |
| alert() 弹提示 | toast 通知（右上角滑入，2.5s 自动消失） |

## 四、必备交互细节

- **加载态**：请求中按钮置灰 + spinner（内联 SVG 或纯 CSS 脉冲点）；列表加载用骨架屏（灰块 + shimmer 动画）
- **空态**：不是一片空白——给一句人话（"还没有报名记录，去看看路线吧"）+ 一个行动按钮
- **Toast**：成功绿/失败红，右上角滑入动画（`transform: translateX(120%) → 0`）
- **表单**：label 常显（不用 placeholder 当 label）、聚焦主色描边、错误内联红字
- **响应式**：`clamp()` 字号、`grid-template-columns: repeat(auto-fill, minmax(280px, 1fr))`、移动端单列
- **微交互**：hover 上浮/变色、按下 `scale(.98)`、数字变化用滚动动画（参考 50projects50days 的 Incrementing Counter）

## 五、AI 助手面板（本技能应用的标配组件）

每个应用页面的 AI 入口统一做成**右下角浮动按钮 + 侧滑面板**（或 hero 区快捷卡）：

- 浮动按钮：56px 圆形，主色渐变 + 彩色投影，hover 轻微放大
- 面板：固定右侧 380px 宽，圆角 24px，毛玻璃底
- 消息气泡：用户消息主色底白字右对齐；AI 消息白底卡片左对齐
- **流式渲染**：读 DSH `/api/agent/stream` SSE，逐字追加；AI 思考中显示三点脉冲动画
- 工具调用过程可见：AI 消息中显示小标签「🔍 正在查询路线库…」增强真实感

## 六、参考资源（生成前可抓取学习）

- 2d-weekend-mall 前端源码：`mall-app/src/main/resources/static/`（styles.css 362 行完整 tokens 实践，**首选参照**）
- dsh-java-mysql 前端源码：`dsh-java-mysql-app/src/main/resources/static/`（管理后台型布局）
- [50projects50days](https://github.com/bradtraversy/50projects50days)：50 个纯 HTML/CSS/JS 小组件（toast、骨架屏、计数器、表单动效），按需抄单个组件
- [SpinKit](https://github.com/tobiasahlin/SpinKit)：纯 CSS loading spinners，`--sk-size/--sk-color` 变量定制
- 布局心法参考 Refactoring UI 要点：层次靠字号/字重/颜色深浅而非线框；间距用 8 的倍数；亲密性分组

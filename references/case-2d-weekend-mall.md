# 案例一：2D Weekend Mall（智能客服）

仓库：https://github.com/fuzhengwei/2d-weekend-mall

PC 端虚拟商城（Spring Boot，内存数据，预置用户 customer-1 与 12 件商品），提供商品搜索、购物车、下单、支付、订单查询、物流跟踪 REST API，页面右上角 AI 客服代理到 DSH。

## 结构

- `mall-app`：商城后端 + PC 前端，端口 18080
- `mall-agent-plugin`：智能客服 Java Native 插件，pluginId = `mall-weekend-assistant`

## 插件工具

| 工具 | 说明 |
| --- | --- |
| `plugin__mall-weekend-assistant__search_products` | 商品搜索 |
| `plugin__mall-weekend-assistant__product_detail` | 商品详情 |
| `plugin__mall-weekend-assistant__order_query` | 订单查询 |
| `plugin__mall-weekend-assistant__order_detail` | 订单详情 |
| `plugin__mall-weekend-assistant__logistics_query` | 物流查询 |

## 关键集成点（对接已有应用时的参考模式）

- **AI 入口代理**：商城 `/api/assistant/stream` 把用户消息代理到 DSH 的 `/api/agent/stream`，默认 Agent `customer-service-demo`。在 `mall-app` 的 application.yml 配置：

```yaml
mall:
  assistant:
    harness-base-url: http://localhost:8090
    agent-id: customer-service-demo
```

- **服务凭证**：DSH 插件配置 `mall.service-token` 必须与商城 `mall.security.service-token` 一致，客服插件凭此查询当前登录用户订单
- **插件配置**：`mall.base-url` 指向商城地址（默认 http://localhost:18080）。修改后需停用再启用插件
- **Hook**：通过 `POST_TOOL_USE` 发出客服审计事件

## 启动与安装

```bash
mvn package -DskipTests
java -jar mall-app/target/*.jar    # http://localhost:18080
# 插件 JAR: mall-agent-plugin/target/mall-agent-plugin-1.0.0-SNAPSHOT.jar
# 用 install_plugin.sh 安装激活，或 DSH 界面上传
```

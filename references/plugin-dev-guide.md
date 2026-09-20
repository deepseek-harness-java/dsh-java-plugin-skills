# DSH Java Native 插件开发指南

本文从两个真实案例（2d-weekend-mall 智能客服插件、dsh-java-mysql MySQL 运维插件）提炼，可直接照此生成工程。

## 1. 工程结构

Maven 多模块（应用 + 插件）：

```text
my-app/
├── pom.xml                       # 聚合 parent
├── my-app/                        # 业务应用 Spring Boot 模块
│   └── src/main/java/...
└── my-agent-plugin/               # 插件模块
    ├── pom.xml
    └── src/main/
        ├── java/cn/xiaofuge/.../MyPlugin.java
        └── resources/
            ├── META-INF/plugin.yaml
            └── META-INF/services/cn.xiaofuge.deepseek.harness.domain.spi.JavaHarnessPlugin
```

## 2. 插件 pom.xml（关键：provided）

```xml
<dependencies>
    <dependency>
        <groupId>cn.xiaofuge</groupId>
        <artifactId>deepseek-harness-java-types</artifactId>
        <version>0.1.5</version>
        <scope>provided</scope>
    </dependency>
</dependencies>
```

⚠️ 必须 `provided`：宿主运行时提供这些类，插件打进依赖会类冲突。

## 3. plugin.yaml

```yaml
id: my-agent-plugin
name: My Agent Plugin
version: 0.1.0
author: you
description: 一句话说明插件能力。
entrypoint: cn.xiaofuge.my.MyPlugin   # 插件主类全限定名（注意：与 install 接口的 entrypoint=JAR文件名 不同！）
```

## 4. SPI 声明

`src/main/resources/META-INF/services/cn.xiaofuge.deepseek.harness.domain.spi.JavaHarnessPlugin`：

```text
cn.xiaofuge.my.MyPlugin
```

## 5. 插件主类骨架

```java
package cn.xiaofuge.my.plugin;

import cn.xiaofuge.deepseek.harness.domain.model.entity.AbstractTool;
import cn.xiaofuge.deepseek.harness.domain.model.entity.ToolDefinition;
import cn.xiaofuge.deepseek.harness.domain.spi.AbstractHarnessPlugin;
import cn.xiaofuge.deepseek.harness.domain.spi.PluginContext;
import cn.xiaofuge.deepseek.harness.domain.spi.PluginHookResult;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;

public class MyPlugin extends AbstractHarnessPlugin {
    public static final String PLUGIN_ID = "my-agent-plugin";

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(3)).build();

    public MyPlugin() { super(PLUGIN_ID); }

    @Override
    public List<ToolDefinition> tools() {
        return List.of(new HelloTool());
    }

    @Override
    public void configure(PluginContext context) {
        super.configure(context);
        // 系统提示词：告诉 Agent 何时/如何用这些工具（写清边界，直接影响调用准确性）
        context.registerSystemPrompt("my-capabilities", 20, """
                ## My Plugin
                - 查询类问题必须调用工具查证真实结果，禁止编造。
                """);
        // Hook：工具调用前后审计
        context.registerHook("PRE_TOOL_USE", (toolName, payloadJson) -> {
            if (toolName != null && toolName.startsWith("plugin__" + PLUGIN_ID + "__")) {
                return PluginHookResult.context("audit: tool call.");
            }
            return null;
        });
    }

    // ---- HTTP 辅助（带超时与异常兜底，返回 JSON） ----
    private String get(String path, Map<String, Object> args) {
        return send(HttpRequest.newBuilder(URI.create(baseUrl(args) + path)).GET().build());
    }
    private String post(String path, String json, Map<String, Object> args) {
        return send(HttpRequest.newBuilder(URI.create(baseUrl(args) + path))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json)).build());
    }
    // 地址可被插件配置/参数覆盖，默认本机
    private String baseUrl(Map<String, Object> args) {
        Object override = args == null ? null : args.get("appBaseUrl");
        return override == null || String.valueOf(override).isBlank()
                ? System.getenv().getOrDefault("MY_APP_BASE_URL", "http://127.0.0.1:18080")
                : String.valueOf(override);
    }
    private String send(HttpRequest request) {
        try {
            HttpResponse<String> resp = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (resp.statusCode() / 100 != 2) return failJson(resp.statusCode(), resp.body());
            return resp.body();
        } catch (Exception e) { return failJson(0, e.getMessage()); }
    }
    private String failJson(int status, String message) {
        return "{\"error\":true,\"status\":" + status + ",\"message\":\"" + json(message) + "\"}";
    }
    private String json(String v) {
        if (v == null) return "";
        return v.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }
    private String str(Map<String, Object> args, String key) {
        Object value = args == null ? null : args.get(key);
        return value == null ? "" : String.valueOf(value);
    }

    // ---- 工具定义 ----
    private class HelloTool extends AbstractTool {
        @Override public String name() { return "hello_query"; }
        @Override public String description() {
            return "查询 xxx，返回真实结果 JSON。何时必须调用/何时不要调用/返回什么都写清楚。";
        }
        @Override public Map<String, Object> parameters() {
            return objectSchema()
                    .prop("keyword", stringSchema("查询关键词"))
                    .required("keyword")
                    .build();
        }
        @Override public boolean isConcurrencySafe(Object args) { return true; }
        @Override protected java.util.concurrent.CompletableFuture<cn.xiaofuge.deepseek.harness.domain.model.entity.ToolExecutionResult>
        run(Map<String, Object> args, cn.xiaofuge.deepseek.harness.domain.model.entity.ToolRunContext ctx) {
            return ok(get("/api/hello?keyword=" + java.net.URLEncoder.encode(
                    str(args, "keyword"), java.nio.charset.StandardCharsets.UTF_8), args));
        }
    }
}
```

`objectSchema()/stringSchema()` 及 `required(...)` 由 types 包提供（见案例源码用法）。写操作类工具需 `isConcurrencySafe` 返回 false 并在 description 中声明风险。

## 6. 构建

```bash
mvn package -DskipTests
# 产物: my-agent-plugin/target/my-agent-plugin-<version>.jar
```

## 7. 安装到 DSH

方式一：脚本（推荐）

```bash
bash <skill_path>/scripts/install_plugin.sh \
  /abs/path/my-agent-plugin-0.1.0.jar my-agent-plugin 0.1.0 my-agent-plugin-0.1.0.jar "My Agent Plugin"
```

方式二：curl

```bash
curl -X POST http://localhost:8090/api/harness/plugins/install \
  -H 'Content-Type: application/json' \
  -d "{\"pluginId\":\"my-agent-plugin\",\"displayName\":\"My Agent Plugin\",\"pluginVersion\":\"0.1.0\",\"runtimeType\":\"JAVA_NATIVE\",\"sourcePath\":\"/abs/path/my-agent-plugin-0.1.0.jar\",\"entrypoint\":\"my-agent-plugin-0.1.0.jar\"}"

curl -X POST http://localhost:8090/api/harness/plugins/activate \
  -H 'Content-Type: application/json' -d '{"pluginId":"my-agent-plugin"}'
```

方式三：界面 — DSH 控制台「设置 → 插件管理 → 选择 JAR」上传后启用。

验证：

```bash
curl http://127.0.0.1:8090/api/harness/plugins
# Agent 中工具名: plugin__my-agent-plugin__hello_query
```

## 8. 设计要点（两个案例的共识）

- **工具 description 是给 Agent 看的**：写明何时必须调用、何时不要调用（如"上下文已有 connectionId 就不要调 list_connections"）、返回什么
- **插件不直连敏感资源**：通过应用 Admin API（HTTP）访问，应用侧做鉴权与二次校验（如 dsh-java-mysql 服务端拒绝非只读 SQL）
- **系统提示词划边界**：如"所有 MySQL 工具只读，禁止生成 UPDATE/DELETE"
- **Hook 做审计**：PRE_TOOL_USE 返回审计上下文
- **可配置项放插件配置**（如 `mall.service-token`、`mall.base-url`），改配置后需停用再启用插件使 `configure()` 重新执行

# Clash / Mihomo 适配

“Clash”可能指配置格式、旧核心、Mihomo 核心或不同 GUI。执行前必须读取应用名称、版本、内核名称和内核版本。只有当前内核支持 VLESS Reality Vision 才继续。

## 官方字段基线

Mihomo 官方 VLESS 文档：

- https://wiki.metacubex.one/config/proxies/vless/

2026-07-27 回读确认的关键字段包括：`type: vless`、`uuid`、`flow: xtls-rprx-vision`、`tls: true`、`servername`、`client-fingerprint`、`reality-opts.public-key`、`reality-opts.short-id` 和 `network: tcp`。

最小模板只保存占位符，不写真实凭证：

```yaml
proxies:
  - name: "Private-Reality"
    type: vless
    server: <VPS_IP_OR_HOST>
    port: 443
    uuid: <UUID>
    udp: true
    network: tcp
    tls: true
    flow: xtls-rprx-vision
    servername: <REALITY_SERVER_NAME>
    client-fingerprint: chrome
    reality-opts:
      public-key: <REALITY_PUBLIC_KEY>
      short-id: <REALITY_SHORT_ID>
```

字段以执行当天官方文档和客户端实现为准。不要把本模板整份覆盖用户现有配置。

## 接入顺序

1. 备份现有 YAML、订阅和规则。
2. 确认实际内核支持上述字段。
3. 把单个 `proxies` 条目合并进现有配置，保留原 DNS、规则集和其他节点。
4. 将节点加入一个可回退的 `select` 组，不立即改 `MATCH` 或全局流量。
5. 启动配置检查；语法错误时回退，不反复猜字段。
6. 只选择新节点，通过客户端真实本地端口检查出口 IP。
7. 节点通过后，再把 AI 域名规则指向统一代理组。
8. 回读连接日志、规则命中和目标服务。

## 常见误区

- GUI 能导入 VLESS 分享链接，不代表实际内核支持 Reality/vision。
- 配置成功加载不代表规则已经命中新节点。
- `mixed-port: 7890` 是常见示例，不是通用端口。
- TUN 开启后，直接探测公网端口可能被代理接管而产生假阳性。
- 不要从随机镜像下载所谓 Clash 客户端；执行当天核对官方项目、发布来源和签名/哈希。

## 验收

至少证明：

- 配置加载无错误；
- 新节点握手成功；
- 本地代理端口返回 VPS 出口 IP；
- OpenAI/Claude/Google 有预期 HTTP 响应；
- AI 域名命中指定代理组；
- 切回旧节点或 DIRECT 的回退有效。

在用户真实 macOS/Windows 设备完成这些证据前，只能报告 `B 文档核对`，不能报告 Clash 路径已验证。

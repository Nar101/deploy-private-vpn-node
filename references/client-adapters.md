# 客户端适配与支持等级

服务端统一使用 VLESS Reality Vision，客户端是可替换适配层。先识别用户已有客户端，不要求为了 Skill 更换工具。

## 能力契约

候选客户端必须在当前版本中支持：

1. VLESS；
2. Reality：public key、short ID、server name、client fingerprint；
3. `xtls-rprx-vision`；
4. TCP 传输；
5. 本地 HTTP/SOCKS 端口或可控 TUN；
6. 节点级选择和可回读日志；
7. 来自官方项目或可信应用商店的可验证发布。

缺少前四项时不要把服务端降级到过时协议来迁就客户端，优先更换支持 Reality 的客户端。

## 当前支持矩阵

| 平台/客户端 | 支持等级 | 当前结论 | 执行入口 |
|---|---|---|---|
| macOS Shadowrocket | A 已实测 | 本机 Reality、规则组、出口与服务均已验证 | `shadowrocket.md` |
| macOS Clash/Mihomo 类 | B 文档核对 | Mihomo 官方文档存在 VLESS Reality Vision 字段；本机未实测 | `clash-mihomo.md` |
| Windows v2rayN | B 文档核对 | 官方项目声明覆盖 Windows 并支持 Xray/sing-box；用户无实机 | `windows.md` |
| Windows Clash/Mihomo 类 | B/C | 取决于具体 GUI 使用的内核版本和配置实现 | `clash-mihomo.md` + `windows.md` |
| sing-box 或其他客户端 | C 标准引导 | 现场核对能力契约和官方文档 | 生成适配计划后逐项验收 |

## 支持等级的报告方式

开始前说清：

```text
服务端路径：A 已实测 / B 文档核对 / C 标准引导
客户端路径：A 已实测 / B 文档核对 / C 标准引导
本次无法保证：具体 GUI 字段、系统权限弹窗、TUN/DNS 行为和当地线路表现
完成依据：节点连接、出口 IP、目标服务、规则命中和回退验证
```

不要用“理论支持”“应该可以”冒充完成。B/C 路径只有在用户真实设备完成验收后，才能把该组合升级为 A。

## 选择原则

- 用户已有可用客户端且满足能力契约：复用现有客户端。
- 用户说“Clash”：先确认具体应用名、版本和实际内核，不把 Clash 当成单一产品。
- Windows 新手：优先选择仍维护、有官方发布与签名/哈希校验、支持 Xray 或 Mihomo 的 GUI。
- 公司电脑：先确认是否允许安装驱动、TUN、系统代理或证书；没有权限时先用本地代理端口做验证。
- 所有平台：先节点级验证，再启用系统代理，最后才启用 TUN 或复杂规则。

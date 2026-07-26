# 腾讯云轻量应用服务器：已验证路径

## 实例快照（2026-07-26）

- 地区：东京
- 系统：Ubuntu 24.04.4 LTS
- 资源：2 vCPU、约 2 GiB 内存、50 GiB 系统盘
- 公网 IP：`<VPS_IP>`（公开版已脱敏）
- 面板：3X-UI 3.5.0
- 内核：Xray 26.6.27
- 主协议：VLESS + Reality + Vision
- 主端口：TCP 443
- 客户端节点名：`<NODE_NAME>`

公网 IP 不是登录凭证，但属于运维资产。不要在对外内容中发布；若工作台仓库改为公开，先移除或脱敏本页 IP。

## 真实搭建链路

```text
腾讯云东京轻量服务器
→ Ubuntu 24.04
→ 3X-UI 管理 Xray
→ VLESS Reality Vision / TCP 443
→ Shadowrocket 本地节点 <NODE_NAME>
→ PROXY
→ AI专用 / OpenAI专用
```

## 两层防火墙

腾讯云轻量应用服务器有两层独立入口控制：

1. 腾讯云控制台防火墙：数据包到达 VPS 前的外层门。
2. Ubuntu UFW：数据包进入操作系统时的内层门。

本次最初的 Reality 和临时 Shadowsocks 同时超时，根因不是 Reality 配置，而是腾讯云外层防火墙只有 SSH 22、HTTP 80 和 ICMP，没有放行 443/8443。加入外层 TCP 443/8443 后两者立即恢复。

最终状态：

- 腾讯云：TCP 443 允许；旧 8443 已删除。
- UFW：22/tcp、443/tcp 允许；8443/tcp、8443/udp 已删除。
- Xray：只对公网提供 TCP 443 主入站。
- 3X-UI 进程监听的面板/订阅端口由防火墙阻断，不向公网交付。

因此，遇到“服务 active、端口也监听，但所有客户端都超时”，必须先查腾讯云外层防火墙，不能直接重装协议。

## 已验证结果

通过 Shadowrocket 本地 SOCKS 端口测试：

- 出口 IP：与当前实例公网 IP 一致
- OpenAI API：`401`，约 1.65 秒
- Anthropic API：`401`，约 1.72 秒
- Google `generate_204`：`204`，约 1.49 秒

未授权 API 返回 401 表示已经连到目标服务，不代表账号或 API Key 有问题。

## 临时诊断方案

排障期间曾增加 `Tokyo-SS-AES`，使用 Shadowsocks AES-128-GCM、TCP/UDP 8443，用于区分“Reality 配置问题”和“公网入口问题”。Reality 恢复并完成独立验证后已：

- 从 Shadowrocket 删除；
- 在 3X-UI 停用；
- 删除 UFW 8443 TCP/UDP；
- 删除腾讯云 8443；
- 删除本地临时配置文件。

不要把它恢复为长期回退。Xray 已明确提示传统 Shadowsocks 模式不推荐继续使用。

## 当前交付边界

- 已交付单节点标准 VLESS 导入文件。
- 已交付 3X-UI 数据库备份。
- 未开放公网订阅服务。单节点导入链接不等于订阅链接；为了减少攻击面，当前不额外开放 2096。
- 数据中心 IP 当前为实例独享出口，但无法保证历史信誉或永久不受风控。

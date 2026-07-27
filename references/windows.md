# Windows 客户端适配

当前用户没有 Windows 实机。本页提供标准流程，不承诺具体版本 UI、驱动权限、TUN/DNS 行为或系统策略一定一致。

## 候选客户端

v2rayN 官方项目：

- https://github.com/2dust/v2rayN

2026-07-27 回读时，项目说明覆盖 Windows、Linux、macOS，可使用 Xray、sing-box 等核心，并提供 GPG 签名校验。它是候选项，不是唯一强制客户端。

Clash/Mihomo 类 GUI 也可作为候选，但必须满足 `client-adapters.md` 的能力契约，并按 `clash-mihomo.md` 核对配置。

## 标准流程

1. 确认 Windows 版本、CPU 架构、管理员权限、公司设备策略和当前代理软件。
2. 从执行当天的官方项目或可信商店下载，核对签名或哈希；不使用来历不明的整合包。
3. 不先启用 TUN。先导入单个 VLESS Reality 节点或最小配置。
4. 回读地址、443、UUID、Reality public key、short ID、server name、fingerprint 和 vision flow。
5. 启动客户端后读取真实本地 HTTP/SOCKS 端口。
6. 用 `curl.exe` 通过该端口检查出口和服务。
7. 节点通过后，再启用系统代理和业务规则；确需 TUN 时单独处理管理员权限与 Windows 防火墙提示。
8. 验证浏览器、命令行和目标应用；记录回退方法。

HTTP 代理示例：

```powershell
curl.exe --proxy http://127.0.0.1:<HTTP_PORT> https://api.ipify.org
curl.exe --proxy http://127.0.0.1:<HTTP_PORT> -o NUL -s -w "OpenAI %{http_code} %{time_total}s`n" https://api.openai.com/v1/models
curl.exe --proxy http://127.0.0.1:<HTTP_PORT> -o NUL -s -w "Claude %{http_code} %{time_total}s`n" https://api.anthropic.com/v1/models
curl.exe --proxy http://127.0.0.1:<HTTP_PORT> -o NUL -s -w "Google %{http_code} %{time_total}s`n" https://www.google.com/generate_204
```

SOCKS 代理示例：

```powershell
curl.exe --proxy socks5h://127.0.0.1:<SOCKS_PORT> https://api.ipify.org
```

端口必须从客户端读取，不猜 `7890`、`10808` 等常见值。

## Windows 特有边界

- 安装虚拟网卡、TUN 驱动、服务或接受 Windows 防火墙放行属于安全敏感动作，动作发生前确认。
- 公司电脑可能由组策略、EDR 或管理员权限限制；不要绕过组织安全策略。
- 系统代理只覆盖遵循代理设置的应用；TUN 覆盖更广，但风险和故障面也更大。
- 退出客户端前先恢复系统代理，避免留下“客户端已关、系统仍指向本地端口”的断网状态。
- 未在真实 Windows 设备完成节点、出口、服务、规则和回退验收前，支持等级保持 B/C。

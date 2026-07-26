# Deploy Private VPN Node · by Nar

> 把一台空白 VPS，交付成可验证、可维护、凭证不外泄的个人 Reality 节点。

Deploy Private VPN Node 是一个运行在 Codex、Claude Code、Cursor 等 Agent 环境中的运维 Skill。它覆盖购买判断、Ubuntu 安全基线、VLESS Reality Vision、Xray/3X-UI、Shadowrocket 接入、双层防火墙、独立验收、备份和维护。

它不是机场面板、公开订阅服务或来源不明的一键安装脚本，只面向个人或极少数受信任设备的合法使用。

**Created by [Nar / 那不然](https://github.com/Nar101)** · Official repository: [`Nar101/deploy-private-vpn-node`](https://github.com/Nar101/deploy-private-vpn-node)

> 本项目最初由 **Nar / 那不然** 设计并开源。欢迎在 MIT License 下使用、修改和再发布；再分发本项目的全部或实质性部分时，请保留原始版权声明与许可证。

## 为什么做它

部署一个节点并不难，真正容易出问题的是交付过程：

- 把一键脚本显示“安装成功”当成节点真的可用；
- 服务器监听了 443，却漏查云厂商外层防火墙；
- 为了方便管理，把 3X-UI 面板、订阅端口或数据库暴露到公网；
- 在聊天、日志、仓库和截图里泄露私钥、UUID、节点链接或 Token；
- 只看一次延迟，不验证真实出口和目标服务；
- 把 `unattended-upgrades active` 误认为安全补丁已经生效；
- 在用户要求不断网时，直接更新内核、网络栈或重启 Xray。

这个 Skill 把这些风险变成明确顺序、证据和阻断条件。

## 30 秒开始

```bash
npx skills add Nar101/deploy-private-vpn-node
```

安装后可以直接说：

```text
使用 deploy-private-vpn-node，帮我检查并维护一台自用 Ubuntu VPS。
先做只读审计，不输出任何私钥、UUID、节点链接或 Token；
如果操作可能让当前网络断线，先停止并说明原因。
```

## 支持的工作模式

| 模式 | 适用场景 |
| --- | --- |
| `new-deploy` | 从 VPS 采购判断到节点交付 |
| `clone` | 复制已验证架构，但重新生成全部实例凭证 |
| `diagnose` | 排查超时、抖动、端口或目标服务不可用 |
| `maintain` | 审计、备份、升级、恢复与收紧暴露面 |

## 它会做什么

- 先区分购买决策、服务器状态和客户端问题；
- 默认采用 Ubuntu LTS、VLESS + Reality + Vision；
- 把云防火墙和 UFW 当作两道独立入口检查；
- SSH 默认使用密钥，禁 root 和密码远程登录；
- 面板和订阅端口默认不向公网开放；
- 用真实客户端验证出口 IP、OpenAI/Claude 401 和 Google 204；
- 区分零断流动作与必须进入维护窗口的动作；
- 提供只读审计、SQLite 热备份和客户端验证脚本。

## 目录

```text
SKILL.md
agents/openai.yaml
references/
  security-and-acceptance.md
  shadowrocket.md
  tencent-lighthouse.md
scripts/
  audit-server.sh
  backup-xui.sh
  verify-client.sh
```

## 脚本

只读审计服务器：

```bash
sudo bash scripts/audit-server.sh
```

热备份 3X-UI SQLite 数据库并执行完整性检查：

```bash
sudo bash scripts/backup-xui.sh /path/to/x-ui-backup.db
```

验证本地 SOCKS 出口和目标服务：

```bash
bash scripts/verify-client.sh \
  --proxy socks5h://127.0.0.1:1082 \
  --expected-ip <VPS_IP>
```

## 已验证范围

当前版本在一台真实的腾讯云轻量应用服务器东京实例上完成了完整部署，并在同一实例上完成一次零断流安全加固：Ubuntu 24.04、3X-UI、Xray、VLESS Reality Vision 和 Shadowrocket。

这证明了当前腾讯云路径，不代表所有供应商、运营商、地区和客户端已经验证。公网 IP 也不等于住宅 IP，当前可访问不代表长期不会触发目标服务风控。

## 隐私与安全边界

- 仓库不包含真实公网 IP、私钥、密码、UUID、Reality 私钥、short ID、Token、分享 URI 或数据库正文；
- Skill 不自动付款、实名、修改全局代理或开放公网订阅；
- 所有敏感交付物保存在本机并使用 `600` 权限；
- 日志中的“未发现失陷迹象”不等于取证级安全证明；
- 涉及内核、SSH、网络栈、443、Xray 重启或云防火墙的动作必须单独判断断流风险。

## 验证公开版本

```bash
bash scripts/validate-public.sh
```

校验包含 Shell 语法、必需文件、敏感文件类型、私钥/节点链接/UUID 字面量、公开 IP 和 SQLite 热备份完整性。

## 作者

**[Nar / 那不然](https://github.com/Nar101)**

我在持续实践一件事：如何让 AI 从一次性回答，走向理解真实环境、遵守操作边界、执行并验证结果。这个 Skill 是其中一个可公开复用的真实样本。

## License

[MIT](./LICENSE)

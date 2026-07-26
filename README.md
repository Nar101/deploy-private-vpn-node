# Deploy Private VPN Node · by Nar

> 不想继续买共享梯子？让 AI 带你从买一台 VPS 开始，搭好真正属于自己的个人节点。

Deploy Private VPN Node 首先服务不懂服务器的新手：你只需要说明预算、所在地区、常用设备和主要用途，AI 负责推荐 VPS；你完成购买和必要确认后，AI 继续完成 Ubuntu、VLESS Reality、Xray/3X-UI 和 Shadowrocket 接入，直到手机或电脑真实可用。

**费用不会做到一半才告诉你。** 这个 Skill 本身免费开源，但租服务器、购买客户端或更换 IP 等第三方服务可能收费。Codex 会在开始前列出全部预计费用、收费周期和续费方式；每次实际付款前再次说明，只有你确认后才继续。

安全基线、双层防火墙、独立验收、备份和维护是第二层能力。它们不是这个 Skill 的主角，而是为了避免“节点看起来装好了，却连不上、泄露凭证或很快坏掉”。

它不是机场面板、公开订阅服务或来源不明的一键安装脚本，只面向个人或极少数受信任设备的合法使用。

**Created by [Nar / 那不然](https://github.com/Nar101)** · Official repository: [`Nar101/deploy-private-vpn-node`](https://github.com/Nar101/deploy-private-vpn-node)

> 本项目最初由 **Nar / 那不然** 设计并开源。欢迎在 MIT License 下使用、修改和再发布；再分发本项目的全部或实质性部分时，请保留原始版权声明与许可证。

## 它首先解决什么

你可能正在使用机场或共享订阅，但希望：

- 不再和很多人共享同一个出口；
- 自己租一台 VPS，拥有一个个人节点；
- 不学习一整套 Linux 和网络术语，也能在 AI 帮助下完成搭建；
- 最终直接导入 Shadowrocket 使用，而不是停在服务器面板显示“运行中”。

这个 Skill 的完成标准很直接：**买对服务器 → AI 完成部署 → 导入客户端 → 真实能用。**

## 费用会在开始前讲清楚

Codex 会先给出完整费用预期，而不是走到支付页面才提示：

- 哪些费用是必需的，哪些是可选的；
- 当前价格和币种；
- 一次性购买还是按月、按年续费；
- 首购优惠结束后的续费价格；
- 是否自动续费；
- 不购买会影响什么。

每次真实付款前，Codex 会再次说明“买什么、为什么、多少钱、以后是否还收费”。付款、实名、验证码和自动续费选择始终由用户完成。

## 为什么还要做后面的安全和验收

对新手来说，节点“装上了”之后仍然有很多坑：

- 把一键脚本显示“安装成功”当成节点真的可用；
- 服务器监听了 443，却漏查云厂商外层防火墙；
- 为了方便管理，把 3X-UI 面板、订阅端口或数据库暴露到公网；
- 在聊天、日志、仓库和截图里泄露私钥、UUID、节点链接或 Token；
- 只看一次延迟，不验证真实出口和目标服务；
- 把 `unattended-upgrades active` 误认为安全补丁已经生效；
- 在用户要求不断网时，直接更新内核、网络栈或重启 Xray。

这个 Skill 把这些风险变成明确顺序、证据和阻断条件，但它们都服务于最初那个目标：让新手真正用上自己的节点。

## 30 秒开始

```bash
npx skills add Nar101/deploy-private-vpn-node
```

安装后可以直接说：

```text
我不想继续买共享梯子了，想自己搭一个个人节点，但我不懂服务器。
使用 deploy-private-vpn-node，先根据我的预算、地区、设备和用途推荐一台 VPS；
开始前先列出全部预计费用，每次实际付款都先说明并等我确认；
买完后请继续帮我搭好，并导入 Shadowrocket，直到真实能用。
```

## 支持的工作模式

| 模式 | 适用场景 |
| --- | --- |
| `new-deploy` | 从 VPS 采购判断到节点交付 |
| `clone` | 复制已验证架构，但重新生成全部实例凭证 |
| `diagnose` | 排查超时、抖动、端口或目标服务不可用 |
| `maintain` | 审计、备份、升级、恢复与收紧暴露面 |

## 它会做什么

- 用大白话了解预算、地区、设备和主要用途；
- 开始前列出必需和可选费用，避免意外收费；
- 给新手一个明确的 VPS 推荐，而不是扔出一堆术语；
- 购买后接管空白 Ubuntu VPS，部署 VLESS + Reality + Vision；
- 生成客户端配置并接入 Shadowrocket；
- 用真实网页/API 和出口 IP 确认节点确实能用；
- 然后再完成凭证保护、防火墙、备份和维护；
- 把云防火墙和 UFW 当作两道独立入口检查；
- SSH 默认使用密钥，禁 root 和密码远程登录；
- 面板和订阅端口默认不向公网开放；
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

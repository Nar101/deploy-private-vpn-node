# 节点故障证据树

## 第一次分叉：服务端是否收到连接

### 没有收到 SYN/443 流量

只查客户端到服务器之前的路径：实例状态、公网 IP、云防火墙、本地路由、TUN 防回环、节点运行快照。不要改 Reality 参数。

### 收到 TCP 或 ClientHello

进入第二次分叉。不要再用 `nc` 可达性重复证明 TCP。

## 第二次分叉：Reality 是否认证

### Reality authentication/validation failed

检查有效配置哈希、时间、short ID、SNI、客户端版本边界和 fallback。读取 `reality-compatibility.md`。

### Reality 认证成功

进入 VLESS/XTLS 层，检查 UUID 哈希、Vision flow、TCP 和客户端序列化。

### 没有 Reality 日志

用 `run-debug-window.sh --redact-config <effective-config.json>` 创建服务器本地看门狗调试窗口。必须先确认正式服务能自动恢复，不能让 SSH 连接承担恢复责任；日志必须经过凭证脱敏。

## 第三次分叉：业务出口是否正确

### 节点成功，出口错误

只查规则顺序、代理组、配置选择和运行日志。

### 出口正确，特定服务失败

区分 DNS、目标服务 IP 信誉、账号风控、协议响应和线路质量；不要重新部署服务器。

### 下载成功但速度不可信

确认测速域名真实命中新节点。若被旧规则送到其他节点，整次结果无效。报告单连接/多连接、文件大小、测试点、时间、网络和 Mbps，不与峰值带宽直接等同。

## 证据表模板

连续三个假设失败后停止修改，填写：

```text
当前正式状态：
服务器收到连接：none / tcp / clienthello
Reality：unknown / failed / passed
VLESS：unknown / failed / passed
出口：unknown / wrong / expected
当前有效配置已回读：yes / no
最近一次只改变的变量：
测试是否受污染：yes / no
已恢复并验证：yes / no
下一条唯一分支：
```

可将这些事实交给 `scripts/diagnose-node.sh` 生成下一步。没有证据的字段必须填 `unknown`，不得猜测。

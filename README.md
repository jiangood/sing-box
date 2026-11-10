# sing-box Docker

基于 [sing-box](https://github.com/SagerNet/sing-box) 的轻量 Docker 镜像，开箱即用的 **VLESS + XTLS-Vision + REALITY** 服务端：

- 单入口，默认 `443/tcp`
- 不需要域名，也不需要证书
- 首次启动自动生成 UUID、REALITY 密钥对和 short_id，并输出可直接导入的分享链接

支持 `linux/amd64` 与 `linux/arm64`。

镜像：`ghcr.io/jiangood/sing-box:latest`

## 特性

- REALITY 借用真实大站的 TLS 握手，抗主动探测：探测者只会看到那个大站的真实证书
- 凭据全部自动生成，启动前用 `sing-box check` 校验配置
- 只做协议转换，出站是 `direct`，出口就是服务器本身
- 配置文件已存在时不会被覆盖，方便自行接管
- 无多余依赖，镜像只保留 sing-box 与 CA 证书

## 快速开始

```bash
docker run -d --name sing-box --restart unless-stopped \
  -v sing-box-data:/etc/sing-box \
  -p 443:443/tcp \
  -e SERVER_ADDR=你的服务器IP或域名 \
  ghcr.io/jiangood/sing-box:latest
```

`SERVER_ADDR` 只用于拼出可直接导入客户端的分享链接；不填则链接里显示 `<server-ip>`，手动替换即可。

查看生成的凭据：

```bash
docker exec sing-box cat /etc/sing-box/credentials.txt
```

```text
vless_uuid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
vless_port=443
vless_sni=www.microsoft.com
vless_public_key=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
vless_short_id=xxxxxxxx
vless_url=vless://...
```

`vless_url` 可以直接复制导入客户端。实时查看日志：

```bash
docker logs -f sing-box
```

停止并删除容器：

```bash
docker rm -f sing-box
```

## 环境变量

| 变量 | 默认值 | 说明 |
|---|---|---|
| `SERVER_ADDR` | `<server-ip>` | 仅用于生成分享链接中的服务器地址 |
| `PORT` | `443` | 容器内监听端口 |
| `PUBLIC_PORT` | 同 `PORT` | 分享链接中的端口；宿主机端口映射到别处时改这个 |
| `REALITY_SNI` | `www.microsoft.com` | REALITY 借用的握手站点，需支持 TLS 1.3 与 HTTP/2，且服务器能直连 |

宿主机 443 被占用时（例如已有 Nginx / Caddy）：

```bash
docker run -d --name sing-box --restart unless-stopped \
  -v sing-box-data:/etc/sing-box \
  -p 8443:8443/tcp \
  -e PORT=8443 -e PUBLIC_PORT=8443 \
  -e SERVER_ADDR=你的服务器IP或域名 \
  ghcr.io/jiangood/sing-box:latest
```

换成非常规端口会降低隐蔽性，能空出 443 就优先用 443。

`REALITY_SNI` 的要求：必须是**别人的**、支持 TLS 1.3 + HTTP/2 的大站，且从你的服务器能直连。`www.microsoft.com`、`www.apple.com` 都是常见选择。不要用自己被墙的域名，更不要用自己的域名——那会立刻暴露这是个代理。

## 客户端配置

最省事的方式是从 `credentials.txt` 复制 `vless_url`：

- **v2rayN**：复制链接 →「从剪贴板导入批量URL」
- **Clash Verge Rev / FlClash**：配置 → 新建 → 从剪贴板导入
- **Karing / Shadowrocket / v2rayNG**：粘贴链接或扫码导入
- **sing-box 官方客户端**：按各自文档转成 outbound（`type: vless` + `tls.reality`）

手工填写时对应关系如下：

| 字段 | 值 |
|---|---|
| 地址 / 端口 | 服务器 IP（或域名）/ `443` |
| UUID | `vless_uuid` |
| 流控 / flow | `xtls-rprx-vision` |
| 传输 / network | `tcp` |
| 安全 / security | `reality` |
| SNI | `vless_sni` |
| 公钥 / pbk | `vless_public_key` |
| shortId / sid | `vless_short_id` |
| 指纹 / fingerprint | `chrome` |

`flow` 必须填；不支持 Vision 的旧客户端会直接连接失败，升级到 v2rayN 6.x、Clash Meta 1.18+ 或 sing-box 1.8+ 即可。

## 验证服务端

不装客户端也能确认 REALITY 是否工作：用 `curl` 直连服务器但把域名解析到服务器 IP。

```powershell
curl.exe -vk --resolve www.microsoft.com:443:你的服务器IP https://www.microsoft.com -o NUL
```

如果 REALITY 正常，握手会成功，证书应该是 `www.microsoft.com` 的真实证书——这正是 REALITY 的伪装效果：未通过认证的连接会被原样转发给真实站点。此时容器日志里会出现一条 `REALITY: processed invalid connection`，属于正常现象，不用管。

若卡住超时，先检查防火墙 / 安全组是否放行了 `443/tcp`。

## Windows PC 客户端

需要让不认系统代理的程序（游戏、部分桌面客户端）也走代理时，用支持 VLESS + REALITY 的客户端导入 `vless_url` 并开启 TUN 或系统代理：

- **[Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev)** — 用户最多，基于 mihomo / sing-box 内核
  - 优点：维护活跃，系统代理与 TUN 一键切换，规则分流、订阅管理、多平台都齐
  - 缺点：概念较多（profile、规则、DNS），新手要花点时间；常驻内存占用偏高
- **[v2rayN](https://github.com/2dust/v2rayN)** — 老牌 Windows 客户端
  - 优点：用户多、中文资料全，协议支持广，测速、日志、路由规则等配套齐全
  - 缺点：选项和菜单繁杂，界面偏工具风格
- **[FlClash](https://github.com/chen08209/FlClash)** — 界面简洁的跨平台 Clash 客户端
  - 优点：配置与 Clash 通用，Windows / macOS / Linux / Android 一套通吃
  - 缺点：功能深度不如 Clash Verge Rev，迭代较快偶有小问题
- **[Hiddify](https://github.com/hiddify/hiddify-app)** — sing-box 内核，一键连接
  - 优点：上手最快，跨平台覆盖最广，含移动端
  - 缺点：偏订阅 / 机场导入，手工填单个节点不直观

这类工具会改写整机路由，不用时先关闭接管模式再退出，避免断网。

## 手机端客户端

直接导入 `vless_url` 即可。按热度（GitHub 星标）排序的前四个：

- **[v2rayNG](https://github.com/2dust/v2rayNG)** — Android 用户最多
  - 优点：教程和中文资料最多，支持剪贴板导入、分应用代理
  - 缺点：仅 Android，界面偏旧
- **[FlClash](https://github.com/chen08209/FlClash)** — Android + 桌面同一套
  - 优点：界面现代，配置与 Clash 通用，手机和 PC 可共用配置文件
  - 缺点：功能深度不如 CMFA 和 Clash Verge Rev，版本迭代快
- **[Clash Meta for Android](https://github.com/MetaCubeX/ClashMetaForAndroid)** — mihomo 内核
  - 优点：规则分流能力强，支持 VLESS + REALITY 和 TUN 接管
  - 缺点：仅 Android，界面朴素，节点要写 YAML
- **[sing-box 官方客户端](https://github.com/SagerNet/sing-box)** — 与本服务同内核
  - 优点：内核同源，兼容性最好；Android、iOS、macOS 都有官方版本
  - 缺点：偏配置文件驱动，图形化程度低

iOS 还可用免费的 [Karing](https://github.com/KaringX/karing)、[Hiddify](https://github.com/hiddify/hiddify-app)，或付费闭源的 Shadowrocket（App Store 购买，iOS 上用户最多）。

## 注意事项

- `443` 需要独占：宿主机已被 Nginx / Caddy 占用时，用 `PORT` 换端口（隐蔽性会下降），或改用前置分流
- REALITY 必须客户端直连，**不支持 CDN 中转**（Cloudflare 等会终止 TLS，握手就露馅了）
- 出站是 `direct`：代理只做协议转换，出口就是服务器本身，不提供额外的跨境能力；速度取决于服务器链路
- `vless_url` 等同于账号密码，不要公开分享；要换凭据就删掉数据卷里的 `config.json` 重启容器
- 已有 `config.json` 时镜像不会覆盖；从旧版本（带 `2080` Mixed 入口）升级上来的数据卷需要删除 `config.json` 才会重新生成
- 客户端里记得把 DNS 也交给代理（TUN 模式默认会接管），否则容易泄漏
- 若同一台 PC 与服务器同处内网，可把地址换成内网地址，省去防火墙放行

## 版本

镜像标签：

- `latest`：跟随最新发布
- `v2.0.0`：固定版本，适合需要锁定版本的环境

把示例中的 `latest` 换成版本号即可：

```bash
docker pull ghcr.io/jiangood/sing-box:v2.0.0
```

当前内置 sing-box `v1.14.4`。工作流只在推送版本标签（例如 `v2.0.0`）时触发，构建并发布多架构镜像，同时更新 `latest`。

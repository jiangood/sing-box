# sing-box Docker

基于 [sing-box](https://github.com/SagerNet/sing-box) 的轻量 Docker 镜像，开箱即用的 Mixed（HTTP / SOCKS5）代理，支持 `linux/amd64` 与 `linux/arm64`。

镜像：`ghcr.io/jiangood/sing-box:latest`

## 特性

- 首次启动自动生成随机密码，用户名固定为 `admin`，启动前用 `sing-box check` 校验配置
- 仅开放 Mixed 入站，默认直连出站，适合本地或内网代理

## 快速开始

一条命令即可启动：

```bash
docker run -d --name sing-box --restart unless-stopped \
  -p 2080:2080/tcp \
  -p 2080:2080/udp \
  ghcr.io/jiangood/sing-box:latest
```

代理地址 `服务器IP:2080`，HTTP 与 SOCKS5 同端口，出站 direct。用户名固定为 `admin`，密码见日志或凭据文件。端口监听所有网卡，可从公网访问，请确保已配置强密码并放行防火墙端口。

查看首次生成的凭据，同样保存在容器内 `/etc/sing-box/credentials.txt`：

```bash
docker logs sing-box
```

实时查看日志：

```bash
docker logs -f sing-box
```

停止并删除容器：

```bash
docker rm -f sing-box
```

## 配置持久化

配置和凭据默认只存在容器内，删除容器即丢失（重跑会重新生成）。如需保留，挂载数据卷：

```bash
docker run -d --name sing-box --restart unless-stopped \
  -v sing-box-data:/etc/sing-box \
  -p 2080:2080/tcp \
  -p 2080:2080/udp \
  ghcr.io/jiangood/sing-box:latest
```

已有的 `config.json` 会直接复用。

## Windows PC 客户端使用

服务端只提供一个带认证的 Mixed 入口（HTTP 与 SOCKS5 共用 `2080` 端口），Windows 侧不需要安装额外服务，按下文任选一种方式接入即可。

### 1. 准备信息

从容器日志或 `/etc/sing-box/credentials.txt` 取到后再开始：

```text
服务器地址：你的服务器公网 IP（或域名）
端口：2080
用户名：admin
密码：一串 48 位十六进制字符
```

用户名固定为 `admin`；密码由 `openssl rand -hex` 生成，只含 `0-9a-f`，放进 URL 时无需转义。

### 2. 先用命令行验证

确认网络和凭据都没问题，再配置系统代理：

```powershell
curl.exe -x http://用户名:密码@服务器IP:2080 https://api.ipify.org
```

返回的 IP 与服务端出口一致即说明可用。若卡住超时，先检查防火墙 / 安全组是否放行了 `2080/tcp`。

### 3. 方式一：Windows 系统代理（推荐，最简单）

适用于 Edge、Chrome、以及大部分使用系统代理的桌面程序。

1. 打开 **设置 → 网络和 Internet → 代理**
2. 在「手动设置代理」中启用 **使用代理服务器**
3. 地址填 `服务器IP`，端口填 `2080`，保存
4. 首次被应用访问时，Windows 会弹出凭据窗口，输入用户名和密码并勾选记住即可

系统代理只支持 HTTP 协议。需要 SOCKS5（例如要代理 UDP）时，用支持 SOCKS5 的客户端工具，见方式二。PowerShell、`curl`、`git` 等命令行工具不走系统代理，需要时按上面的验证命令显式指定代理参数。

### 4. 方式二：全局接管（开源客户端）

需要让不认系统代理的程序（游戏、部分桌面客户端）也走代理时，可自行下载安装支持 SOCKS5 认证的开源客户端。用法一致：添加 SOCKS5 节点，填 `服务器IP`、`2080`、用户名和密码，再按各自文档开启 TUN 或进程分流。

- **[Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev)** — 用户最多，基于 mihomo / sing-box 内核
  - 优点：维护活跃，系统代理与 TUN 一键切换，规则分流、订阅管理、多平台都齐
  - 缺点：概念较多（profile、规则、DNS），新手要花点时间；常驻内存占用偏高
- **[v2rayN](https://github.com/2dust/v2rayN)** — 老牌 Windows 客户端
  - 优点：用户多、中文资料全，协议支持广，测速、日志、路由规则等配套齐全
  - 缺点：选项和菜单繁杂，界面偏工具风格；只用 SOCKS5 显得偏重
- **[FlClash](https://github.com/chen08209/FlClash)** — 界面简洁的跨平台 Clash 客户端
  - 优点：配置与 Clash 通用，Windows / macOS / Linux / Android 一套通吃
  - 缺点：功能深度不如 Clash Verge Rev，迭代较快偶有小问题
- **[Hiddify](https://github.com/hiddify/hiddify-app)** — sing-box 内核，一键连接
  - 优点：上手最快，跨平台覆盖最广，含移动端
  - 缺点：偏订阅 / 机场导入，手工填单个 SOCKS5 节点不直观

这类工具会改写整机路由，不用时先关闭接管模式再退出，避免断网。

### 注意事项

- 系统代理是明文 HTTP 代理，凭据也随请求头发送。建议只在可信网络使用，或在前置反向代理上加 TLS
- 服务端出站是 `direct`，即代理只做协议转换，不提供翻墙能力；跨地域访问速度取决于链路质量
- 修改系统代理后记得在不用时关闭，否则断网状态下所有应用都会连接超时
- 若同一台 PC 与服务器同处内网，可把 `服务器IP` 换成内网地址，省去防火墙放行

## 手机端客户端

服务端凭据与 PC 通用：在客户端里新建 SOCKS5 节点，填 `服务器IP`、`2080`、用户名和密码即可。按热度（GitHub 星标）排序的前四个：

- **[v2rayNG](https://github.com/2dust/v2rayNG)** — Android 用户最多
  - 优点：教程和中文资料最多，支持手填 SOCKS5、分应用代理
  - 缺点：仅 Android，界面偏旧，生态以 v2ray 系协议为主
- **[FlClash](https://github.com/chen08209/FlClash)** — Android + 桌面同一套
  - 优点：界面现代，配置与 Clash 通用，手机和 PC 可共用配置文件
  - 缺点：功能深度不如 CMFA 和 Clash Verge Rev，版本迭代快
- **[Clash Meta for Android](https://github.com/MetaCubeX/ClashMetaForAndroid)** — mihomo 内核
  - 优点：规则分流能力强，支持 SOCKS5 节点和 TUN 接管
  - 缺点：仅 Android，界面朴素，节点要写 YAML
- **[sing-box 官方客户端](https://github.com/SagerNet/sing-box)** — 与本服务同内核
  - 优点：内核同源，兼容性最好；Android、iOS、macOS 都有官方版本
  - 缺点：偏配置文件驱动，图形化程度低

iOS 还可用免费的 [Karing](https://github.com/KaringX/karing)、[Hiddify](https://github.com/hiddify/hiddify-app)，或付费闭源的 Shadowrocket（App Store 购买，iOS 上用户最多）。

## 版本

镜像标签：

- `latest`：跟随最新发布
- `v1.0.0`：固定版本，适合需要锁定版本的环境

把示例中的 `latest` 换成版本号即可：

```bash
docker pull ghcr.io/jiangood/sing-box:v1.0.0
```

当前内置 sing-box `v1.14.4`。工作流只在推送版本标签（例如 `v1.0.0`）时触发，构建并发布多架构镜像，同时更新 `latest`。

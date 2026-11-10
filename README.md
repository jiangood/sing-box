# sing-box Docker

基于 [sing-box](https://github.com/SagerNet/sing-box) 的轻量 Docker 镜像，开箱即用的 Mixed（HTTP / SOCKS5）代理，支持 `linux/amd64` 与 `linux/arm64`。

镜像：`ghcr.io/jiangood/sing-box:latest`

## 特性

- 首次启动自动生成随机用户名和密码，启动前用 `sing-box check` 校验配置
- 仅开放 Mixed 入站，默认直连出站，适合本地或内网代理

## 快速开始

一条命令即可启动：

```bash
docker run -d --name sing-box --restart unless-stopped \
  -p 127.0.0.1:2080:2080/tcp \
  -p 127.0.0.1:2080:2080/udp \
  ghcr.io/jiangood/sing-box:latest
```

代理地址 `127.0.0.1:2080`，HTTP 与 SOCKS5 同端口，出站 direct。端口只监听回环地址，不会暴露到公网。

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
  -p 127.0.0.1:2080:2080/tcp \
  -p 127.0.0.1:2080:2080/udp \
  ghcr.io/jiangood/sing-box:latest
```

已有的 `config.json` 会直接复用。

## 版本

镜像标签：

- `latest`：跟随最新发布
- `v1.0.0`：固定版本，适合需要锁定版本的环境

把示例中的 `latest` 换成版本号即可：

```bash
docker pull ghcr.io/jiangood/sing-box:v1.0.0
```

当前内置 sing-box `v1.14.4`。工作流只在推送版本标签（例如 `v1.0.0`）时触发，构建并发布多架构镜像，同时更新 `latest`。

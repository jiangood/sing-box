# sing-box Docker

[sing-box](https://github.com/SagerNet/sing-box) 核心的轻量 Docker 镜像，开箱即用的 Mixed（HTTP / SOCKS5）代理，支持 `linux/amd64` 与 `linux/arm64`。

镜像：`ghcr.io/jiangood/sing-box:latest`

## 特性

- 首次启动自动生成随机用户名和密码，无需手写配置
- 仅开放 Mixed 入站，默认直连出站，适合本地或内网代理
- 多架构镜像，`latest` 跟随最新发布的版本标签
- 启动前自动执行 `sing-box check` 校验配置

## 快速开始

无需克隆仓库或准备配置文件，复制执行：

```bash
docker run -d --name sing-box --restart unless-stopped \
  -p 127.0.0.1:2080:2080/tcp \
  -p 127.0.0.1:2080:2080/udp \
  ghcr.io/jiangood/sing-box:latest
```

代理地址为 `127.0.0.1:2080`，HTTP 与 SOCKS5 共用同一端口，出站默认 direct。端口仅绑定宿主机回环地址，不会直接暴露到公网。

查看首次生成的凭据：

```bash
docker logs sing-box
docker exec sing-box cat /etc/sing-box/credentials.txt
```

## 常用命令

查看日志：

```bash
docker logs -f sing-box
```

停止并删除容器：

```bash
docker rm -f sing-box
```

## 配置持久化

默认情况下配置和凭据只保存在容器内，删除容器后会一并丢失，重新运行会生成新凭据。如需保留，可挂载数据卷：

```bash
docker run -d --name sing-box --restart unless-stopped \
  -v sing-box-data:/etc/sing-box \
  -p 127.0.0.1:2080:2080/tcp \
  -p 127.0.0.1:2080:2080/udp \
  ghcr.io/jiangood/sing-box:latest
```

已存在的 `config.json` 会被直接复用，不会重新生成。

## 构建与发布

- 推送到 `main`、Pull Request 或手动触发：只构建验证，不发布镜像
- 推送版本标签（例如 `v1.0.0`）：构建并发布多架构镜像，同时更新 `latest`

核心程序由 [SagerNet/sing-box](https://github.com/SagerNet/sing-box) 提供。

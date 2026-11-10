# sing-box Docker Image

一个精简的 sing-box 运行镜像项目。容器只负责运行官方 sing-box 核心，不再包含 VPS 一键安装脚本、交互式管理菜单、systemd/OpenRC、Caddy 或系统调优功能。

## 镜像

```text
ghcr.io/jiangood/sing-box:latest
```

支持 `linux/amd64` 和 `linux/arm64`。镜像以官方 `ghcr.io/sagernet/sing-box` 为基础，不在本项目中重新编译核心。

## 快速启动

1. 克隆仓库并编辑 `config/config.json`。
2. 启动容器：

```bash
docker compose up -d
docker compose logs -f sing-box
```

默认示例配置启动一个监听容器 2080 端口的 mixed 入站，并将流量直连。请在公网部署前按自己的用途修改配置、认证信息和监听端口。

## 使用自己的配置

将配置目录挂载到容器的 `/etc/sing-box`。默认启动命令等价于：

```bash
sing-box -D /var/lib/sing-box -C /etc/sing-box run -c /etc/sing-box/config.json
```

可以在 Compose 中通过 `command` 覆盖参数。配置文件应符合当前 sing-box 版本的配置格式。

检查配置：

```bash
docker compose run --rm sing-box check -c /etc/sing-box/config.json
```

更新并重建容器：

```bash
docker compose pull
docker compose up -d
```

日志直接输出到 Docker stdout/stderr：

```bash
docker compose logs -f sing-box
```

## 端口与网络

示例 Compose 映射 TCP 和 UDP 的 2080 端口。若你的配置使用其他端口或协议，请同步调整 `ports`。使用 Hysteria2、TUIC 等 UDP 入站时，务必映射对应 UDP 端口。

若需要 host 网络，可在 Compose 服务中设置 `network_mode: host`，并移除 `ports`；host 网络模式下端口映射不会生效。

## 自定义 sing-box 版本

Dockerfile 的 `SING_BOX_VERSION` 默认值和发布工作流中的 `SING_BOX_VERSION` build-arg 需要保持一致。升级时将两处改为官方 GHCR 中存在的版本标签，然后提交即可触发构建。

## 自动构建

GitHub Actions 在推送到 `main`、推送 `v*` 标签或手动触发时构建并发布镜像到 GHCR，目标平台为 amd64/arm64。Pull Request 只构建验证，不推送镜像。

首次发布后，如希望其他用户无需登录即可拉取，请到 GitHub 仓库的 Packages 页面将该容器包可见性设为 Public。

## 目录结构

```text
.
├── .github/workflows/docker-publish.yml
├── .dockerignore
├── Dockerfile
├── docker-compose.yml
└── config/
    └── config.json
```

## 许可

本项目原有许可文件见 [LICENSE](LICENSE)。sing-box 核心由 [SagerNet/sing-box](https://github.com/SagerNet/sing-box) 项目提供。

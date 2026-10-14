# Dify 离线安装包

一键离线部署 [Dify](https://github.com/langgenius/dify) —— 集成 Dify **1.17.1** 全部默认组件的 Docker 镜像与官方部署文件，全程不需要连接 Docker Hub，适用于内网、安可环境、企业防火墙受限等离线场景。

> 典型症状：内网机器上执行 `docker compose up -d` 时卡在 Pulling，最后报
> `failed size validation: xxx != yyy: failed precondition`。
> 这是防火墙/中间设备干扰了镜像层下载，用本离线包可以绕过。

## 版本

| 项目 | 值 |
| --- | --- |
| Dify 版本 | 1.17.1（官方发布于 2026-09-10） |
| 部署文件 | 对应官方仓库 `v1.17.1` 标签的 `docker/` 目录 |
| 镜像架构 | linux/amd64 |
| 默认组件组合 | 向量库 weaviate + 数据库 postgresql + collaboration（官方 1.17.1 默认） |

## 仓库内容

| 路径 | 说明 |
| --- | --- |
| `docker/` | Dify 1.17.1 官方部署文件（docker-compose.yaml、.env.example、nginx/ssrf_proxy 配置、按需 envs 等），未做任何改动 |
| `load-images.sh` | 一键导入脚本：自动合并分卷 + 逐个 `docker load` |
| `.github/workflows/` | 构建脚本。Dify 出新版时点一下就能产出新一份离线包 |

**Docker 镜像不在仓库里**，在 [Releases](../../releases) 页面（单包 6-8GB，放仓库会拖垮 clone 速度）。

## 一、离线安装（内网/无外网）

### 前置要求

- 目标机已安装 Docker 与 Docker Compose v2
- 目标机为 x86_64 / amd64 架构
- 磁盘预留 ≥ 20GB

### 步骤

**1. 下载**

在能上网的机器上打开本仓库的 [Releases](../../releases) 页面，下载 `SHA256SUMS.txt`、`load-images.sh` 以及全部镜像文件（`.tar` 或 `.tar.partNN`），拷贝到目标机同一个目录里。

传输前可校验：`sha256sum -c SHA256SUMS.txt`

**2. 导入镜像**

```bash
bash load-images.sh
```

脚本会自动把 `xxx.tar.part00`、`xxx.tar.part01`… 合并回 `xxx.tar`，再逐个导入。结束后 `docker images` 应能看到 12 个镜像。

也可以手动导入（分卷文件先合并）：

```bash
cat dify-api_1.17.1.tar.part* > dify-api_1.17.1.tar
docker load -i dify-api_1.17.1.tar
```

**3. 启动**

```bash
cd docker
cp .env.example .env
docker compose up -d
```

**4. 访问**

浏览器打开 `http://<服务器IP>/`，首次访问会跳到初始化页面，自行设置管理员账号和密码即可。

默认端口 80（可在 `docker/.env` 里改 `EXPOSE_NGINX_PORT`）。

## 二、联网安装

只想用官方部署文件、不需要离线包时：

```bash
cd docker
cp .env.example .env
docker compose up -d
```

镜像会从 Docker Hub 直接拉取（国内网络建议配置镜像加速器）。

## 三、包含的镜像（12 个）

| 镜像 | 对应服务 |
| --- | --- |
| `langgenius/dify-api:1.17.1` | api / worker / worker_beat / api_websocket |
| `langgenius/dify-web:1.17.1` | web（前端） |
| `langgenius/dify-sandbox:0.2.15` | sandbox |
| `langgenius/dify-agent-backend:1.17.1` | agent_backend |
| `langgenius/dify-agent-local-sandbox:1.17.1` | local_sandbox |
| `langgenius/dify-plugin-daemon:0.6.10-local` | plugin_daemon（插件运行时） |
| `postgres:15-alpine` | db_postgres |
| `redis:6-alpine` | redis |
| `ubuntu/squid:latest` | ssrf_proxy / agent_ssrf_proxy |
| `nginx:latest` | nginx |
| `busybox:latest` | init_permissions |
| `cr.weaviate.io/semitechnologies/weaviate:1.39.2` | weaviate（默认向量库） |

以上即官方 `docker-compose.yaml` 在默认 `.env` 下启动的全部服务。官方 compose 里另有 Milvus、Elasticsearch、Chroma、Qdrant、OceanBase 等 19 个**可选**向量库组件，默认不启用，未包含在本包内。

## 四、常见问题

**Q：`docker compose up -d` 报 `failed size validation` 或拉取反复中断？**
防火墙在干扰 Docker Hub。用本离线包，`docker compose up -d` 就不会再去拉镜像。

**Q：80 端口被占用？**
编辑 `docker/.env`，把 `EXPOSE_NGINX_PORT=80` 改成 8062 之类，再 `docker compose up -d`。

**Q：启动后容器一直重启？**
先看日志：`docker compose logs -f api`。多数是 `.env` 没复制（步骤 3 的 `cp .env.example .env` 漏了）。

**Q：想换成别的向量库？**
改 `docker/.env` 里的 `VECTOR_STORE`，同时需要该向量库的镜像（本包未包含），联网或另行导入。

## 五、升级到新版本

Dify 出新版后：

1. 在 Actions 页面点 **Build Dify Offline Package** → **Run workflow**，填入新版本对应的标签（如 `v1.18.0`）
2. 等待构建完成，新 Release 会自动带上全部镜像
3. 同时把 `docker/` 目录更新到新版本（来自官方仓库对应 tag）

## 许可

部署文件与镜像版权归 [Dify](https://github.com/langgenius/dify) 项目所有，遵循其开源许可。本仓库仅做离线打包与整合。

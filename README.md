# Dify 离线安装包

一键离线部署 [Dify](https://github.com/langgenius/dify) —— 集成 Dify **1.17.1** 全部默认组件的 Docker 镜像与官方部署文件，全程不需要连接 Docker Hub，适用于内网、安可环境、企业防火墙受限等离线场景。

> 典型症状：内网机器上执行 `docker compose up -d` 卡在 Pulling，最后报
> `failed size validation: xxx != yyy: failed precondition`。
> 这是防火墙 / 中间设备干扰了镜像层下载，用本离线包可以绕过。

## 版本

| 项目 | 值 |
| --- | --- |
| Dify 版本 | 1.17.1（官方发布于 2026-09-10） |
| 部署文件 | 取自官方仓库 `v1.17.1` 标签的 `docker/` 目录，未做改动 |
| 镜像架构 | linux/amd64 |
| 默认组件组合 | weaviate（向量库）+ postgresql（数据库）+ collaboration，即官方 1.17.1 的默认配置 |

## 文件在哪

| 位置 | 内容 |
| --- | --- |
| **[Releases](../../releases) 页面** | 全部 Docker 镜像 `.tar`、部署文件 `dify-docker-deploy-<版本>.zip`、导入脚本 `load-images.sh`、校验和 `SHA256SUMS.txt` |
| **本仓库** | 部署文件的源码形式 `docker/`、导入脚本、构建工作流 |

镜像体积大（合计约 8GB），只放在 Releases，不进仓库。

## 一、离线安装（内网 / 无外网）

### 前置要求

- 目标机已安装 Docker 与 Docker Compose v2
- 目标机为 x86_64 / amd64 架构
- 磁盘预留 ≥ 25GB

### 步骤

**1. 下载**

在能上网的机器上打开本仓库的 [Releases](../../releases) 页面，下载全部文件：

- `dify-docker-deploy-1.17.1.zip` —— 官方部署文件
- `load-images.sh` —— 镜像导入脚本
- `SHA256SUMS.txt` —— 校验和
- `langgenius_dify-api_1.17.1.tar.part00`、`.part01`…… 等全部镜像文件

下载后可选校验完整性：`sha256sum -c SHA256SUMS.txt`

**2. 导入镜像**

把上面所有文件拷到目标机同一个目录，执行：

```bash
bash load-images.sh
```

脚本会先把 `xxx.tar.part00`、`.part01`… 自动合并回 `xxx.tar`，再逐个 `docker load`，最后列出结果。结束后 `docker images` 应能看到 12 个镜像。

也可以手动导入（分卷文件需先合并）：

```bash
cat langgenius_dify-api_1.17.1.tar.part* > langgenius_dify-api_1.17.1.tar
docker load -i langgenius_dify-api_1.17.1.tar
```

**3. 解压部署文件并启动**

```bash
unzip dify-docker-deploy-1.17.1.zip      # 得到 docker/ 目录
cd docker
cp .env.example .env
docker compose up -d
```

**4. 访问**

浏览器打开 `http://<服务器IP>/`，首次访问会跳到初始化页面，自行设置管理员账号和密码。

默认端口 80，可在 `docker/.env` 里改 `EXPOSE_NGINX_PORT`。

> 镜像导入完成后，`.tar` 文件即可删除（约 8GB），容器运行不受影响。

## 二、联网安装

只需要官方部署文件、不需要离线镜像时：

```bash
git clone https://github.com/lxyztmds/dify-offline.git
cd dify-offline/docker
cp .env.example .env
docker compose up -d
```

镜像会从 Docker Hub 直接拉取（国内网络建议先配镜像加速器）。

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
防火墙在干扰 Docker Hub。用本离线包导入镜像后再启动，就不会再去拉镜像。

**Q：80 端口被占用？**
编辑 `docker/.env`，把 `EXPOSE_NGINX_PORT=80` 改成 8062 之类端口，再 `docker compose up -d`。

**Q：启动后容器一直重启？**
先看日志：`docker compose logs -f api`。最常见原因是漏了 `cp .env.example .env`（没有 `.env` 服务起不来）。

**Q：想换成别的向量库？**
改 `docker/.env` 里的 `VECTOR_STORE`，同时需要该向量库的镜像（本包未包含，需联网拉取或另行导入）。

**Q：GitHub Releases 下载太慢？**
`langgenius_dify-api_1.17.1.tar` 约 3GB，其余单个不超过 1.6GB。可借助 GitHub 加速代理下载。

## 五、升级到新版本

Dify 出新版后：

1. 把 `docker/` 目录更新到官方对应 tag（唯一需要改的地方，其余文件里写死了版本号的地方见下）
2. 修改 `.github/workflows/build-offline-package.yml` 里 `matrix.image` 的版本号，以及 `README.md`、`RELEASE_NOTES.md` 中的版本描述
3. 在 Actions 页面点 **Build Dify Offline Package** → **Run workflow**，填入新标签（如 `v1.18.0`）
4. 等待构建完成，新 Release 会自动带上全部镜像、部署文件 zip 与校验和

## 许可

部署文件与镜像版权归 [Dify](https://github.com/langgenius/dify) 项目所有，遵循其开源许可。本仓库仅做离线打包与整合。

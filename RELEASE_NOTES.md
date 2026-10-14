## Dify 离线安装包

集成 Dify **1.17.1** 全部默认组件的 Docker 镜像，适配内网 / 安可环境 / 企业防火墙等无法访问 Docker Hub 的离线场景。

- 镜像架构：`linux/amd64`
- 全部镜像以 tar 形式导出；单个文件超过 1.9GB 的自动分卷，文件名形如 `xxx.tar.part00`
- 完整性校验：`sha256sum -c SHA256SUMS.txt`

### 镜像清单（12 个）

| 镜像 | 对应服务 |
| --- | --- |
| `langgenius/dify-api:1.17.1` | api / worker / worker_beat / api_websocket |
| `langgenius/dify-web:1.17.1` | web |
| `langgenius/dify-sandbox:0.2.15` | sandbox |
| `langgenius/dify-agent-backend:1.17.1` | agent_backend |
| `langgenius/dify-agent-local-sandbox:1.17.1` | local_sandbox |
| `langgenius/dify-plugin-daemon:0.6.10-local` | plugin_daemon |
| `postgres:15-alpine` | db_postgres |
| `redis:6-alpine` | redis |
| `ubuntu/squid:latest` | ssrf_proxy / agent_ssrf_proxy |
| `nginx:latest` | nginx |
| `busybox:latest` | init_permissions |
| `cr.weaviate.io/semitechnologies/weaviate:1.39.2` | weaviate |

### 快速开始

把本页所有文件和仓库里的 `load-images.sh` 放在目标机同一个目录：

```bash
# 1. 导入镜像（自动合并分卷）
bash load-images.sh

# 2. 启动
cd docker
cp .env.example .env
docker compose up -d
```

浏览器打开 `http://<服务器IP>/`，首次访问设置管理员账号即可。默认端口 80。

完整说明、常见问题与升级方式见仓库 [README](https://github.com/lxyztmds/dify-offline#readme)。

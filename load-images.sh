#!/usr/bin/env bash
# 一键导入 Dify 离线镜像
#
# 用法：把本脚本和从 Release 下载的镜像文件（*.tar 或 *.tar.partNN）放在同一个目录，
#       然后执行：bash load-images.sh
#
# 脚本会自动完成：合并分卷 -> docker load -> 列出导入结果。

set -euo pipefail
cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "错误：找不到 docker 命令，请先安装 Docker。" >&2
  exit 1
fi

echo "==> 1/3 合并分卷文件（如有）"
for part in *.tar.part00; do
  [ -e "$part" ] || continue
  base="${part%.part00}"
  echo "    合并 ${base%.*} -> ${base}"
  cat "${base}".part* > "$base"
  rm -f "${base}".part*
done

echo "==> 2/3 导入镜像"
shopt -s nullglob
tars=(*.tar)
if [ ${#tars[@]} -eq 0 ]; then
  echo "错误：当前目录没有找到 .tar 镜像文件。" >&2
  exit 1
fi
for f in "${tars[@]}"; do
  echo "    docker load -i $f"
  docker load -i "$f"
done

echo "==> 3/3 导入完成，本地镜像列表："
docker images

echo
echo "全部镜像已导入。接下来："
echo "  cd docker && cp .env.example .env && docker compose up -d"

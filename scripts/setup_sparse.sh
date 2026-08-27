#!/usr/bin/env bash
# 稀疏检出（non-cone）：始终拉取公共目录 + 各模块 docs/release/README.md，
# 额外参数指定要「全量」拉取的模块。
#
# 用法:
#   bash scripts/setup_sparse.sh              # 只拉公共 + 各模块文档结构
#   bash scripts/setup_sparse.sh module_A     # 再全量拉 module_A
#   bash scripts/setup_sparse.sh module_A module_B
#
# 使用 --stdin 写入规则，避免 Git Bash(Windows) 把 /module_X/... 参数改写成盘符路径。
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: 请在仓库内执行" >&2
  exit 1
fi

# non-cone：先包含根目录文件，再排除根下子目录，随后按需加回
patterns=('/*' '!/*/' '/.github/**' '/.githooks/**' '/scripts/**')

# 从 Git 树枚举一级目录（不依赖当前工作区是否已检出）
mapfile -t top_dirs < <(git ls-tree -d --name-only HEAD)

full_modules=()
for arg in "$@"; do
  full_modules+=("$arg")
done

contains() {
  local needle=$1
  shift
  local x
  for x in "$@"; do
    [[ "$x" == "$needle" ]] && return 0
  done
  return 1
}

for dir in "${top_dirs[@]}"; do
  # 跳过隐藏目录与公共目录
  [[ "$dir" == .* ]] && continue
  [[ "$dir" == "scripts" ]] && continue
  [[ "$dir" == "docs" ]] && continue

  if contains "$dir" "${full_modules[@]+"${full_modules[@]}"}"; then
    patterns+=("/${dir}/**")
  else
    # 非全量模块：只拉 docs / release / 同级 README.md（不带上同级其他文件）
    patterns+=("/${dir}/docs/**" "/${dir}/release/**" "/${dir}/README.md")
  fi
done

# 校验全量模块名是否存在
for m in "${full_modules[@]+"${full_modules[@]}"}"; do
  if ! contains "$m" "${top_dirs[@]}"; then
    echo "ERROR: 模块不存在: $m" >&2
    echo "可用一级目录: ${top_dirs[*]}" >&2
    exit 1
  fi
done

echo "sparse-checkout set --no-cone -> ${patterns[*]}"
printf '%s\n' "${patterns[@]}" | git sparse-checkout set --no-cone --stdin

git config core.hooksPath .githooks
echo "已启用钩子: core.hooksPath=.githooks"

if [ ${#full_modules[@]} -eq 0 ]; then
  echo "未指定全量模块：各模块仅 docs/ + release/ + README.md"
else
  echo "全量模块: ${full_modules[*]}"
fi

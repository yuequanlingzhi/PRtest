# PRtest

多模块示例仓库。约定每个一级模块目录必须包含 `README.md`、`docs/`、`release/`；改动通过 PR 合入 `main`，禁止直推。

## 前置认知

- 分支分本地与云端两份，彼此独立。
- `git switch -c` 只建**本地**分支；`git push -u` 才会在云端创建分支。
- `git branch -d/-D` 只删本地；删云端分支需另外操作。

## ① 一次性准备（每人一次）

稀疏拉取已脚本化：`scripts/setup_sparse.sh` 会自动拉齐**必拉内容**，再按参数全量拉指定模块。

**必拉（无需手写）：**

- 公共目录：`.github/`、`.githooks/`、`scripts/`
- 每个模块的 `docs/`、`release/`、同级 `README.md`（显式拉取，不带同级其他文件）
- 仓库根目录文件（如根 `README.md`）

**全量：** 把要完整开发的模块名作为参数传入。

```bash
git clone --filter=blob:none --sparse https://github.com/yuequanlingzhi/PRtest.git
cd PRtest
git sparse-checkout set scripts          # 先检出脚本
bash scripts/setup_sparse.sh module_A    # 必拉全部 + 全量 module_A
```
```

常用用法：

```bash
bash scripts/setup_sparse.sh                 # 只拉公共 + 各模块文档结构
bash scripts/setup_sparse.sh module_A        # 再全量拉 A
bash scripts/setup_sparse.sh module_B        # 换成全量 B
bash scripts/setup_sparse.sh module_A module_B   # A、B 都全量
```

脚本会同时执行 `git config core.hooksPath .githooks`。启用后 `git push` 会：

- 拦截直推 `main`
- 打印当前分支的 PR 创建链接

## ② 日常开发 → PR → 合并

```bash
git switch main && git pull
git switch -c feature/你的改动          # 修 bug 可用 fix/xxx
# 改 module_A/ 或 module_B/ 下内容
git add module_A/                       # 或对应模块路径
git commit -m "feat(module_A): 说明"
git push -u origin feature/你的改动     # 推上云端；误推 main 会被钩子拦下
```

到 GitHub：

1. 打开钩子打印的 `Create PR` 链接（或在仓库页 Compare & pull request）。
2. base 选 `main`，按模板填写描述（见下）。
3. 等 CI 全绿后再合（建议 Squash and merge）。

### PR 描述（模板）

模板文件：`.github/PULL_REQUEST_TEMPLATE.md`（需已合入默认分支 `main` 才会自动带出）。

| 区块 | 要求 |
| --- | --- |
| 变更摘要 | **必填**，1～3 句正文 |
| 影响模块 | **必填**；选项可增删改，勾一项或改成正文说明均可 |
| 文档更新 | 可选，有改动再勾；选项可增删改 |
| 测试情况 | **必填**；选项可增删改，勾一项或改成正文说明均可 |
| 关联问题 | **必填**，如 `#12`，无则写「无」 |
| 自审确认 | **必填**，必须勾选 |

### CI 检查

| Workflow | 作用 |
| --- | --- |
| `Check Directory Structure` | 每个一级模块须含 `README.md`、`docs/`、`release/` |
| `Check PR Template` | 校验 PR 描述是否按模板必填项填写完整 |

CI 红了按报错改完后重推，或编辑 PR 描述后会自动重跑模板校验。

## 模块约定

```text
module_X/
  README.md
  docs/
  release/
```

当前模块：`module_A`、`module_B`。

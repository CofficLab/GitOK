# Commit 规范

> 本规范定义了 GitOK 项目的 Git 提交信息编写约定，参考 Lumi 项目的 commit 规范制定。

---

## 格式

```
<type>(<scope>): <description>
```

- **type** 和 **description** 必填，使用英文
- **scope** 可选，但推荐填写
- description 使用小写开头，不加句号，使用祈使语气（如 `add ...`、`fix ...`）

---

## Type

| type | 用途 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(Sidebar): add project search bar` |
| `fix` | 修复 bug | `fix(git): decode non-UTF-8 diff output (GBK/GB18030)` |
| `refactor` | 重构（不改变行为） | `refactor(commit): rename package to ProviderCommit` |
| `style` | 样式/格式调整（不改变行为） | `style(commit-list): unify theme tokens and tighten commit rows` |
| `perf` | 性能优化 | `perf(commit-list): cache diff rendering for large files` |
| `chore` | 杂务、依赖更新、构建脚本 | `chore: update Package.resolved` |
| `docs` | 文档变更 | `docs(commit): add commit convention` |
| `test` | 测试相关 | `test(commit): add kernel boot + observation model coverage` |

---

## Scope

scope 为**模块名或组件名**，使用 PascalCase 或 kebab-case，与代码中的包/插件命名保持一致。

### 常见 scope 示例

| 范围 | scope 示例 |
|------|-----------|
| 入口/组合根 | `FactoryGitOK` |
| 核心框架 | `KernelCore` |
| Kit 包 | `KitGit`、`KitOpenIn`、`KitLocalization`、`KitSuperLog` |
| UI 组件库 | `LumiUI` |
| Provider（能力契约） | `ProviderCommit`、`ProviderProjects`、`ProviderSidebar`、`ProviderStatusBar` |
| 插件 | `PluginCommitList`、`PluginCommitDetail`、`PluginOpenXcode`、`PluginStatusBar` |
| 界面区域 | `Sidebar`、`StatusBar`、`CommitList`、`CommitDetail`、`GitDiff` |

### 规则

- 插件相关变更使用插件包名作为 scope（如 `PluginCommitList`）
- Provider 契约变更使用 Provider 包名（如 `ProviderCommit`）
- 跨多个模块的变更可省略 scope（如 `chore: update dependencies`）
- 单个 scope 无法覆盖时，选择最核心的模块，或将变更拆分为多次提交

---

## Description 规范

- 使用**祈使语气**：`add ...`、`fix ...`、`remove ...`、`update ...`
- **小写开头**，结尾**不加句号**
- 简明扼要，一句话概括变更内容
- 如需更多细节，在空行后添加正文（body），但通常一句话即可

### ✅ 好的 description

```
feat(Sidebar): add project search bar
fix(git): decode non-UTF-8 diff output (GBK/GB18030)
refactor(commit): rename package to ProviderCommit; add commit toast plugin
```

### ❌ 避免的 description

```
feat(Sidebar): Added context menu.    ← 不要过去式，不要句号
fix: 修复了一个 bug                    ← 不要中文，不要过于模糊
chore                                 ← 缺少 description
```

---

## 完整示例

```
feat(commit-list): show working-tree status header

fix(git): decode non-UTF-8 diff output (GBK/GB18030)

style(commit-detail): unify theme tokens and tighten commit rows

refactor(open-in): split into one plugin per target

chore: update Package.resolved and bump project.yml

docs(commit): add commit convention
```

---

## 拆分提交

- 一个提交只做**一件事**
- 不相关的变更拆分为多次提交
- 重构和功能新增分开提交
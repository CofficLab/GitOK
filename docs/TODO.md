# TODO

## P0：核心 Git 工作流

- [ ] OAuth/device-flow 登录、账号多配置、组织分页和头像/权限缓存
- [ ] 一键创建远程仓库、公开/私有选择、平台认证与远端仓库创建
- [ ] 过滤后提交前的最终确认摘要

## P1：高级 Git 操作

- [ ] 交互式 rebase 列表
- [ ] squash 前提交消息编辑预览
- [ ] reset 前自动 stash/备份提示

## P1：远程平台接入

- [ ] 应用内 PR 列表、当前分支关联 PR 状态、review/check 摘要和草稿 PR 创建
- [ ] 应用内未读计数、review/comment 通知流、标记已读和原生评论编辑
- [ ] 平台 issue 搜索、PR 文本编辑器内 autocomplete、用户头像/真实 handle、emoji 全量索引和离线缓存
- [ ] 应用内 check 状态、失败日志摘要、PR check 汇总、rerun 权限判断和原生 rerun 操作
- [ ] 各平台的 OAuth/token 配置界面

## P1：Diff 与设置

- [ ] 默认 diff mode、长行策略和折叠阈值提升为用户设置
- [ ] 语法高亮策略提升为用户设置
- [ ] 图片 diff 补尺寸、文件大小和缩放比例等元信息
- [ ] 超大 diff 阈值做成设置项

## P1：认证与网络

- [ ] 菜单触发的 fetch/pull/push 失败也接入认证弹窗，并补 OAuth/SSO 平台登录
- [ ] 接入原生 askpass/Keychain passphrase 写入，减少用户跳转终端的步骤
- [ ] PAC 自动发现、按仓库覆盖网络配置，以及更细的代理认证凭据保存

## P2：桌面体验

- [ ] Command Palette（可选）
- [ ] 真正的 crash reporter、持久化跨会话错误队列，以及错误弹窗中的"一键附加诊断信息"
- [ ] 更多插件自定义控件的细粒度 VoiceOver 文案

## 已有功能打磨

- [ ] Git-Clone 扩展 SSH passphrase、企业 SSO/OAuth 和平台仓库列表选择

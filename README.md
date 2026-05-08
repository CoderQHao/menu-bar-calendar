# MenuBarCalendar

一个面向中文用户的 macOS 菜单栏日历应用。

它常驻在菜单栏，点击后弹出月历面板，提供农历、节气、法定节假日、调休和周末区分，适合日常查看日期和节假日安排。

## 功能

- 菜单栏实时显示日期和星期
- 点击展开中文月历面板
- 支持前后月份切换和回到今天
- 支持农历、传统节日、节气显示
- 支持法定节假日和调休状态标注
- 支持跟随系统 / 浅色 / 深色模式切换
- 支持 macOS 12 及以上

## 下载

- 预构建版本请前往 GitHub Releases 页面下载 `MenuBarCalendar-unsigned.dmg`
- 如果你下载的是未签名版本，macOS 可能会提示来自未认证开发者，需要在系统设置中手动放行

Releases 页面：

- [https://github.com/CoderQHao/menu-bar-calendar/releases](https://github.com/CoderQHao/menu-bar-calendar/releases)

## 安装

1. 下载 `MenuBarCalendar-unsigned.dmg`
2. 打开 `dmg`
3. 将 `MenuBarCalendar.app` 拖入 `Applications`
4. 首次打开时如果被系统阻止，到 `系统设置 > 隐私与安全性` 中允许打开

## 本地开发

### 要求

- Xcode 26 或更高版本
- macOS 12 或更高版本

### 运行

1. 打开 `MenuBarCalendar.xcodeproj`
2. 选择 `MenuBarCalendar` scheme
3. 运行到 `My Mac`

也可以命令行构建：

```bash
xcodebuild \
  -project MenuBarCalendar.xcodeproj \
  -scheme MenuBarCalendar \
  -configuration Debug \
  build
```

## 工程结构

```text
MenuBarCalendar/
├── Assets.xcassets
├── MenuBarCalendar.xcodeproj
├── Sources/MenuBarCalendar
│   ├── App
│   ├── Models
│   ├── Services
│   ├── Support
│   ├── ViewModels
│   └── Views
└── SupportingFiles
```

## 当前状态

- 已完成标准 macOS Xcode 工程搭建
- 已完成菜单栏入口和月历面板基础交互
- 已完成 `2026.json` 节假日资源接入
- 当前发布包为未签名版本，适合测试和预览

## 后续计划

- 接入远程节假日同步和本地缓存更新
- 补齐正式 App Icon
- 配置正式 Bundle ID、签名和 notarization
- 发布已签名的正式 DMG

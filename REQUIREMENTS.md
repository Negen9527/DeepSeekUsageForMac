# DeepSeekUsageForMac — 需求文档

## 1. 项目概述

**DeepSeekUsageForMac** 是一个 macOS 桌面组件（Floating Desktop Widget），用于实时查看 DeepSeek 平台 API 的用量和费用信息。应用以悬浮窗口形式常驻桌面，从 DeepSeek 平台 API 获取数据，并以可视化图表展示。

**目标用户**：DeepSeek 平台开发者，需要随时掌握 API Token 消耗和费用情况。

**技术栈**：SwiftUI + AppKit（macOS 14.0+），Swift 原生实现，无需第三方依赖。

---

## 2. 核心功能

### 2.1 认证方式
- **不使用 API Key 登录流程**：应用启动直接进入仪表盘
- 首次使用时仪表盘显示空白/占位状态
- 主界面右上角有一个**设置按钮**（齿轮图标），点击打开配置面板
- 在配置面板中输入用户的 **Token**（Bearer Token），保存到 macOS Keychain
- 配置 Token 后，应用自动调用接口获取用量数据并刷新仪表盘

### 2.2 用量数据获取

调用两个 DeepSeek 平台接口，每月自动刷新：

#### 接口 1：用量统计
```
GET https://platform.deepseek.com/api/v0/usage/amount?month={MM}&year={YYYY}
Authorization: Bearer {TOKEN}
```
返回当月 Token 用量明细（输入/输出 Token 数、请求次数等）

#### 接口 2：费用统计
```
GET https://platform.deepseek.com/api/v0/usage/cost?month={MM}&year={YYYY}
Authorization: Bearer {TOKEN}
```
返回当月费用明细（总费用、各模型费用等）

**刷新策略**：
- 每 15 分钟自动刷新（使用当前月份参数）
- 支持手动刷新按钮
- 网络不可用时展示上次缓存数据

### 2.3 配置面板

点击主界面右上角设置按钮后弹出（Sheet 或独立小窗口），包含：

| 配置项 | 说明 |
|------|------|
| Token | SecureField 输入，保存到 Keychain，支持修改和清除 |
| 月度预算 | 金额输入（¥），用于计算预算使用百分比 |
| 立即刷新 | 按钮，触发手动刷新数据 |
| 上次更新时间 | 只读显示 |

### 2.4 仪表盘展示（核心界面）

仪表盘采用 **深色主题 + 图表卡片** 布局，三种尺寸模式（紧凑/中等/完整），默认完整模式。

#### 完整模式（Large）
| 区域 | 内容 |
|------|------|
| 标题栏 | "DeepSeek 用量" + 尺寸切换 + 设置按钮 + 加载指示器 |
| 统计卡片行 | 3 张卡片横排：本月总费用、本月 Tokens、本月请求数 |
| 用量分布 | 环形饼图（输入/输出 Token 比例）+ 进度条 |
| 7 日趋势图 | 折线图/柱状图可切换，展示近 7 天每日 Token 消耗量 |
| 月度对比 | 本月 vs 上月（费用/Tokens/请求数 + 涨跌箭头） |
| 费用汇总 | 本月费用 / 月度预算，渐变色进度条 |
| 底部 | 品牌标识 "DeepSeek" + 更新时间 |

#### 中等模式（Medium）
| 区域 | 内容 |
|------|------|
| 左侧 | 环形仪表盘（预算使用百分比） |
| 右侧 | 输入 Tokens 卡片 + 本月请求卡片 + 费用进度条 |

#### 紧凑模式（Compact）
| 区域 | 内容 |
|------|------|
| 居中 | 环形仪表盘（预算使用百分比） |
| 下方 | 本月费用数值 + DeepSeek 品牌标识 |

### 2.5 图表动画效果
所有图表在数据加载/切换时需有过渡动画，不能是纯静态图：

| 组件 | 动画 | 时长 | 曲线 |
|------|------|------|------|
| 环形仪表盘 (CircularGaugeView) | 弧线从 0 绘制到目标百分比 | 1.0s | easeOut |
| 趋势折线图 (TrendLineChartView) | 线条从左到右渐进绘制 + 数据点渐显 | 1.2s | easeOut |
| 趋势柱状图 (TrendChartViewCompact) | 柱子逐个从底部生长 | 0.5s/根，错开 0.06s | easeOut |
| 饼图/环形图 (AnimatedPieChartView) | 扇区依次绘制，先输入后输出 | 0.8s + 0.3s 延迟 | easeOut |
| 进度条 (UsageProgressBar) | 宽度从 0 滑动到目标 | 0.8s | easeOut |
| 统计卡片 (StatsCardView) | 缩放 (0.85→1.0) + 淡入，逐个错开 | 0.4s/张 | spring |

### 2.6 菜单栏快捷访问
- 菜单栏显示 DeepSeek 图标，点击弹出小型面板
- 面板显示：本月总费用（大字）、输入/输出 Tokens、请求数、月度预算进度条
- 未配置 Token 时提示用户前往设置

### 2.7 WidgetKit 扩展
- 支持系统小组件（通知中心）：小、中、大三种尺寸
- 数据通过 App Group UserDefaults 与主应用共享
- 小组件每 15 分钟自动刷新

---

## 3. 视觉设计规范

### 3.1 配色方案（深色主题）

| 用途 | 色值 | 变量名 |
|------|------|--------|
| 主背景 | `rgb(15, 23, 30)` 深蓝黑 | `background` |
| 卡片背景 | `rgb(22, 32, 42)` | `surface` |
| 卡片浅底 | `rgb(30, 42, 54)` | `surfaceLight` |
| 高亮卡片 | `rgb(35, 47, 58)` | `surfaceElevated` |
| 主强调色 | `rgb(0, 242, 255)` 青色 | `accentCyan` |
| 绿色（输入） | `rgb(20, 164, 117)` | `accentGreen` |
| 黄色（请求） | `rgb(255, 186, 31)` | `accentYellow` |
| 红色（警告） | `rgb(255, 82, 82)` | `accentRed` |
| 橙色 | `rgb(255, 149, 0)` | `accentOrange` |
| 主文字 | 白色 `#FFFFFF` | `textPrimary` |
| 次要文字 | 60% 透明白 | `textSecondary` |
| 弱化文字 | 35% 透明白 | `textMuted` |

### 3.2 渐变色
- 仪表盘/费用进度条使用多色渐变：绿 → 黄绿 → 黄 → 橙 → 红
- 标题栏使用青色渐变：青 → 60%透明青

### 3.3 圆角规范
- 外层卡片：10pt
- 内部卡片：8pt
- 进度条/柱状图：2.5–3pt
- 配置面板：16pt

---

## 4. 数据模型

### 4.1 API 接口

| 接口 | 方法 | URL | 说明 |
|------|------|-----|------|
| 用量统计 | GET | `https://platform.deepseek.com/api/v0/usage/amount?month={MM}&year={YYYY}` | Token 用量明细 |
| 费用统计 | GET | `https://platform.deepseek.com/api/v0/usage/cost?month={MM}&year={YYYY}` | 费用明细 |

**请求头**：`Authorization: Bearer {USER_TOKEN}`

### 4.2 WidgetSnapshot（共享快照）
序列化为 JSON 存入 App Group UserDefaults，供主应用和小组件共用：
- `lastUpdated`: 更新时间
- `monthlyUsage`: 月度用量（输入/输出 Tokens、请求数、费用、预算）
- `trend[]`: 7 日趋势（dateString, tokens, requests, cost）
- `monthlyComparison`: 月度对比（本月 vs 上月）

### 4.3 计算属性
- `totalTokens = promptTokens + completionTokens`
- `budgetUsedFraction = min(cost / monthlyBudget, 1.0)`
- `budgetUsedPercentage = Int(budgetUsedFraction * 100)`

---

## 5. 项目结构

```
DeepSeekUsageForMac/
├── Shared/                              # 主应用与小组件共享
│   ├── Constants/AppConstants.swift      # 常量
│   ├── Models/WidgetSnapshot.swift       # 共享快照模型
│   └── Theme/AppTheme.swift              # 配色和图标常量
├── DeepSeekUsageApp/                     # 主应用
│   ├── DeepSeekUsageApp.swift            # @main 入口（直接进入仪表盘）
│   ├── Services/
│   │   ├── DeepSeekAPIService.swift       # API 调用（usage/amount + usage/cost）
│   │   ├── KeychainService.swift          # Keychain 安全存取 Token
│   │   └── UsageTrackerService.swift      # 本地用量历史记录
│   ├── ViewModels/DashboardViewModel.swift # 数据状态管理
│   └── Views/
│       ├── DesktopWidgetView.swift        # 桌面悬浮窗口（主仪表盘 + 设置按钮）
│       ├── ConfigPanelView.swift          # 配置面板（Token、预算）
│       ├── MenuBarContentView.swift       # 菜单栏面板
│       └── SettingsView.swift             # 设置窗口（可保留备用）
└── DeepSeekUsageWidget/                  # WidgetKit 扩展
    ├── DeepSeekUsageWidget.swift          # Widget 入口
    ├── Provider.swift                     # TimelineProvider
    └── Views/
        ├── SmallWidgetView.swift
        ├── MediumWidgetView.swift
        ├── LargeWidgetView.swift
        └── Components/
            ├── CircularGaugeView.swift    # 环形仪表盘
            ├── AnimatedPieChartView.swift # 饼图/环形图
            ├── TrendChartView.swift       # 趋势柱状图
            ├── TrendLineChartView.swift   # 趋势折线图
            ├── UsageProgressBar.swift     # 用量进度条
            └── StatsCardView.swift        # 统计卡片
```

---

## 6. 非功能需求

| 需求 | 规格 |
|------|------|
| 最低系统 | macOS 14.0 (Sonoma) |
| 架构 | Apple Silicon (arm64) |
| 窗口行为 | 悬浮（floating level），始终在其他窗口之上 |
| 窗口位置 | 默认屏幕右上角 |
| 数据刷新 | 每 15 分钟自动 + 手动触发 |
| 安全 | Token 存储在 macOS Keychain，内存中不打印日志 |
| 离线 | 无网络时展示上次缓存数据 |
| 配置面板 | Sheet 弹出，点击外部可关闭 |

---

## 7. 待办事项

### 需求变更（v2）
- [ ] 移除 LoginView 登录流程，应用启动直接进仪表盘
- [ ] 移除 `/user/balance` 接口，替换为 `usage/amount` + `usage/cost`
- [ ] 主界面右上角添加设置按钮（齿轮图标）
- [ ] 新增 ConfigPanelView：Token 输入 + 月度预算 + 手动刷新
- [ ] 更新 DeepSeekAPIService：适配两个新接口，支持 month/year 参数
- [ ] 更新 DashboardViewModel：移除 balance 逻辑，适配新的用量/费用数据模型
- [ ] 更新 DeepSeekUsageApp：移除登录/仪表盘切换逻辑，直接显示仪表盘
- [ ] 更新 MenuBarContentView：未配置 Token 时显示引导提示
- [ ] 更新 WidgetSnapshot：移除 balance 字段，适配新数据结构
- [ ] 重新编译验证 + 提交

### 基础架构
- [x] 项目结构搭建（Shared / App / Widget 三模块）
- [x] 主题配色：AppTheme（深色主题 7 色体系）
- [x] 常量配置：AppConstants（App Group、刷新间隔等）
- [x] 构建脚本：build.sh（编译 + 打包 + 签名）

### 服务层
- [x] KeychainService：安全存取（macOS Keychain）
- [x] UsageTrackerService：本地用量历史记录（90天），构建 WidgetSnapshot

### 图表组件（全部带动画）
- [x] CircularGaugeView：环形仪表盘，弧线从 0 绘制
- [x] TrendChartViewCompact：7 日柱状趋势图，柱子逐根生长
- [x] TrendLineChartView：7 日折线趋势图，线条渐进绘制
- [x] AnimatedPieChartView：环形饼图，输入/输出 Token 比例
- [x] UsageProgressBar：横向进度条，宽度滑动动画
- [x] StatsCardView：统计卡片，缩放 + 淡入动画

### WidgetKit 扩展
- [x] Small/Medium/Large WidgetView + Provider

### 已完成
- [x] Large 模式底部添加品牌标识 + 更新时间
- [x] 趋势图折线/柱状可切换
- [x] 月度对比（本月 vs 上月）

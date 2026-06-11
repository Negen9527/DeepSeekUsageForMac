# DeepSeekUsageForMac — 需求文档

## 1. 项目概述

**DeepSeekUsageForMac** 是一个 macOS 桌面组件（Floating Desktop Widget），用于实时查看 DeepSeek API 的用量信息。应用以悬浮窗口形式常驻桌面，从 DeepSeek 官方 API 获取余额和用量数据，并以可视化图表展示。

**目标用户**：DeepSeek API 的开发者用户，需要随时掌握 API 用量、Token 消耗和费用情况。

**技术栈**：SwiftUI + AppKit（macOS 14.0+），Swift 原生实现，无需第三方依赖。

---

## 2. 核心功能

### 2.1 API Key 认证
- 首次启动时显示登录界面，用户输入 DeepSeek API Key
- API Key 通过调用 `GET https://api.deepseek.com/user/balance` 进行验证
- 验证通过后，API Key 安全存储在 macOS Keychain 中
- 后续启动自动读取 Keychain，跳过登录直接进入仪表盘

### 2.2 用量数据获取
- 每 15 分钟自动刷新，调用 DeepSeek 余额接口
- 获取数据：余额（总余额/赠送余额/充值余额）、币种、是否可用
- 本地记录每日用量历史（Tokens 消耗、请求次数、费用），保留最近 90 天
- 支持手动刷新

### 2.3 仪表盘展示（核心界面）

仪表盘采用 **深色主题 + 图表卡片** 布局，分为三种尺寸模式：

#### 完整模式（Large）
| 区域 | 内容 |
|------|------|
| 顶部统计卡片行 | 3 张卡片横排：剩余余额、本月 Tokens、本月请求数 |
| 用量分布 | 环形饼图（输入/输出 Token 比例）+ 进度条（百分比数值） |
| 7 日趋势图 | 柱状图展示近 7 天每日 Token 消耗量，今日高亮 |
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
| 下方 | 剩余余额数值 + DeepSeek 品牌标识 |

### 2.4 图表动画效果
所有图表在数据加载/切换时需有过渡动画，不能是纯静态图：

| 组件 | 动画 | 时长 | 曲线 |
|------|------|------|------|
| 环形仪表盘 (CircularGaugeView) | 弧线从 0 绘制到目标百分比 | 1.0s | easeOut |
| 趋势柱状图 (TrendChartView) | 柱子逐个从底部生长 | 0.5s/根，错开 0.06s | easeOut |
| 饼图/环形图 (PieChartView) | 扇区依次绘制，先输入后输出 | 0.8s + 0.3s 延迟 | easeOut |
| 进度条 (UsageProgressBar) | 宽度从 0 滑动到目标 | 0.8s | easeOut |
| 统计卡片 (StatsCardView) | 缩放 (0.85→1.0) + 淡入，逐个错开 | 0.4s/张 | spring |
| 登录卡片 | 上滑 + 淡入 | 0.5s | easeOut |

### 2.5 菜单栏快捷访问
- 菜单栏显示 DeepSeek 图标，点击弹出小型面板
- 面板显示：剩余余额（大字）、输入/输出 Tokens、请求数、月度预算进度条

### 2.6 设置窗口
- API Key 管理：输入、验证、清除
- 月度预算设置：输入金额，用于计算预算使用百分比
- 手动刷新按钮 + 上次更新时间显示

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

---

## 4. 数据模型

### 4.1 DeepSeek API 响应 (`BalanceResponse`)
```
GET https://api.deepseek.com/user/balance
Authorization: Bearer <API_KEY>
```
响应字段：`is_available`, `balance_infos[]` (含 `currency`, `total_balance`, `granted_balance`, `topped_up_balance`)

### 4.2 WidgetSnapshot（共享快照）
序列化为 JSON 存入 App Group UserDefaults，供主应用和小组件共用：
- `lastUpdated`: 更新时间
- `balance`: 余额快照（币种、总额、赠送、充值）
- `monthlyUsage`: 月度用量（输入/输出 Tokens、请求数、费用、预算）
- `trend[]`: 7 日趋势（dateString, tokens, requests, cost）

### 4.3 计算属性
- `totalTokens = promptTokens + completionTokens`
- `budgetUsedFraction = min(cost / monthlyBudget, 1.0)`
- `budgetUsedPercentage = Int(budgetUsedFraction * 100)`

---

## 5. 项目结构

```
DeepSeekUsageForMac/
├── Shared/                              # 主应用与小组件共享
│   ├── Constants/AppConstants.swift      # 常量（App Group ID、Keychain Key、刷新间隔）
│   ├── Models/BalanceInfo.swift          # API 响应模型
│   ├── Models/WidgetSnapshot.swift       # 共享快照模型 + 计算属性 + 格式化
│   └── Theme/AppTheme.swift              # 配色和图标常量
├── DeepSeekUsageApp/                     # 主应用
│   ├── DeepSeekUsageApp.swift            # @main 入口
│   ├── Services/
│   │   ├── DeepSeekAPIService.swift       # API 调用
│   │   ├── KeychainService.swift          # Keychain 存储
│   │   └── UsageTrackerService.swift      # 本地用量历史记录
│   ├── ViewModels/DashboardViewModel.swift # 数据状态管理
│   └── Views/
│       ├── LoginView.swift                # 登录界面（API Key 输入）
│       ├── DesktopWidgetView.swift        # 桌面悬浮窗口（主仪表盘）
│       ├── MenuBarContentView.swift       # 菜单栏面板
│       └── SettingsView.swift             # 设置窗口
└── DeepSeekUsageWidget/                  # WidgetKit 扩展
    ├── DeepSeekUsageWidget.swift          # Widget 入口
    ├── Provider.swift                     # TimelineProvider
    └── Views/
        ├── SmallWidgetView.swift          # 小尺寸
        ├── MediumWidgetView.swift         # 中尺寸
        ├── LargeWidgetView.swift          # 大尺寸
        └── Components/
            ├── CircularGaugeView.swift    # 环形仪表盘
            ├── AnimatedPieChartView.swift # 饼图/环形图
            ├── TrendChartView.swift       # 趋势柱状图
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
| 安全 | API Key 存储在 macOS Keychain，内存中不打印日志 |
| 离线 | 无网络时展示上次缓存数据 |

---

## 7. 待办事项

### 基础架构
- [x] 项目结构搭建（Shared / App / Widget 三模块）
- [x] 数据模型：BalanceInfo、BalanceResponse、WidgetSnapshot
- [x] 主题配色：AppTheme（深色主题 7 色体系）
- [x] 常量配置：AppConstants（App Group、刷新间隔等）
- [x] 构建脚本：build.sh（编译 + 打包 + 签名）

### 服务层
- [x] DeepSeekAPIService：调用 `/user/balance` 接口，Bearer 认证
- [x] KeychainService：API Key 安全存取（macOS Keychain）
- [x] UsageTrackerService：本地用量历史记录（90天），构建 WidgetSnapshot

### 视图层
- [x] LoginView：居中登录卡片，API Key 输入 + 验证，动画入场
- [x] DesktopWidgetView：三种尺寸仪表盘（紧凑/中等/完整）
- [x] MenuBarContentView：菜单栏下拉面板（余额 + Tokens + 请求数）
- [x] SettingsView：API Key 管理、月度预算设置、手动刷新

### 图表组件（全部带动画）
- [x] CircularGaugeView：环形仪表盘，弧线从 0 绘制
- [x] TrendChartView / TrendChartViewCompact：7 日柱状趋势图，柱子逐根生长
- [x] AnimatedPieChartView：环形饼图，输入/输出 Token 比例，扇区依次展开
- [x] UsageProgressBar：横向进度条，宽度滑动动画
- [x] StatsCardView：统计卡片，缩放 + 淡入动画

### WidgetKit 扩展
- [x] SmallWidgetView：小尺寸（环形图 + 余额 + 品牌）
- [x] MediumWidgetView：中尺寸（环形图 + Tokens 卡片 + 费用进度条）
- [x] LargeWidgetView：大尺寸（统计卡片 + 饼图 + 趋势图 + 费用汇总）
- [x] Provider.swift：TimelineProvider，从 App Group 读取快照

### 待完成
- [x] Large 模式底部添加品牌标识 "DeepSeek" + 更新时间
- [x] 趋势图增加折线图选项（当前仅有柱状图）
- [x] 增加月度对比（本月 vs 上月）
- [ ] 增加按模型（chat/reasoner）拆分的 Token 统计（需 DeepSeek API 支持，当前 `/user/balance` 不返回模型维度数据）
- [ ] 添加应用图标（AppIcon 需设计稿）

---

## 8. 待确认项

1. **UI 参考图**：`ui.png` 无法查看，请确认仪表盘布局是否符合预期，或补充描述需要调整的部分
2. **登录流程**：当前为 API Key 直接输入验证，是否需要改为用户名+密码登录？
3. **数据维度**：当前仅展示余额和用量汇总，是否需要按模型（deepseek-chat / deepseek-reasoner）拆分？
4. **趋势图类型**：当前为柱状图，是否需要改为折线图？
5. **月度统计**：是否需要增加月度对比（本月 vs 上月）？

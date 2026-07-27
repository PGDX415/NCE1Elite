# CLAUDE.md — NCE1 Elite 项目开发规范

> 本文件是 Claude Code 在本仓库中工作的唯一权威开发规范。
> 每次开始任务前，请先完整阅读本文件；实现与本文件冲突时，以本文件为准，如有歧义在实现前向用户确认。
>
> **最后更新**：2026-07-27 · 版本 1.0 · 基于 NCE2 Elite 项目规范改编（待开发）

---

## 1. 项目简介

**App 名称**：新概念英语1（Bundle Display Name）/ NCE1 Elite

一个支持浅色/深色模式的 iOS/iPadOS 音频学习应用，用于播放《新概念英语》第一册（Book 1, First Things First）**共 144 课**课文录音（**英音发音**）。**不做单元（Unit）分组，全部课程以扁平列表形式按课号 1–144 顺序呈现。** 支持只听模式和边听边看模式（中英双语文本），播放前倒计时、睡眠定时器、循环模式、倍速播放、收藏、进度记忆等功能。

**核心原则：**
- 离线优先：音频和文本均可由用户本地导入
- 版权合规：App 作为框架壳分发，不含版权内容；内置 Lesson 01–02 作为试听预览（开发阶段保留全部 144 课用于测试）**（此为沿用惯例的假设值，如需调整试听范围请告知）**
- 英伦学院风的视觉语言：安静、克制、有质感

**与 NCE2 Elite 的关键差异：**
- 第一册共 144 课（vs 第二册 96 课），课程简短，适合入门学习者
- 课文内容为情景对话和基础句型为主（vs 第二册的短文故事）
- 音频文件命名：`Lesson1.mp3`（单位数课号不带前导零）或 `Lesson001.mp3`（三位数课号），最终以实际资源文件命名为准

---

## 2. 技术栈

- **语言 / 框架**：Swift 5.10+，SwiftUI + `@Observable`
- **最低系统版本**：iOS 17.0 / iPadOS 17.0
- **音频播放**：`AVFoundation`（`AVAudioPlayer`）+ `AVAudioPlayerDelegate`（精准的播放结束检测）
- **后台播放**：`MPNowPlayingInfoCenter` + `MPRemoteCommandCenter` + `beginBackgroundTask`
- **持久化**：`SwiftData`（`LessonProgress`）
- **用户偏好**：`@AppStorage`（字体大小、显示模式）
- **架构**：MVVM，所有 ViewModel 为 `@Observable class`
- **无第三方依赖**：全部使用系统框架

---

## 3. 品牌与设计系统

### 3.1 配色

浅色模式为默认主题。深色模式通过 `Color(light:dark:)` 自适应切换。

| 用途 | 名称 | 浅色 HEX | 深色 HEX |
|---|---|---|---|
| 主背景 | `background` | `#F6F1E7` | `#0E1A2B` |
| 卡片背景 | `card` | `#FCFAF5` | `#1A2233` |
| 主品牌色 | Oxford Blue | `#1A3A6B` | `#4A8FE7`（亮蓝） |
| 点缀金 | Antique Gold | `#B8973F` | `#D4A843` |
| 主文字 | `text` | `#1C1C1E` | `#E5E0D8` |
| 次要文字 | `textSecondary` | `#5B6472` | `#9CA3AF` |
| 分隔线 | `separator` | `#D9D2C2` | `#2A3341` |
| 酒红 | Bordeaux | `#6E0F1A` | 同左 |

- 全书不分单元，因此**不再使用"英伦旗三色循环"给分组着色**；三色（bordeaux / oxfordBlue / antiqueGold）仅作为品牌点缀色，用于图标、按钮高亮、进度条等 UI 元素
- 首页标题旁保留迷你 Union Jack 三色旗标装饰（纯装饰，与课程分组无关）
- 副标题含 🇬🇧 英国国旗 emoji

### 3.2 字体

- `NCE1Typography` 统一管理所有字体样式（`playerTitle`、`lessonTitle`、`listHeader`、`brandTitle`、`body`、`caption`、`monoDigit`）

---

## 4. App 图标

- 需生成标准 / 深色 / Tinted 三个变体（1024×1024 PNG）
- 位于 `Assets.xcassets/AppIcon.appiconset/`
- 设计：参照 NCE2Elite / NCE3Elite 图标风格——白色背景、Oxford Blue 边框与顶部纹饰，中央为金色 `1`（Georgia Bold），底部金色 `NCE 1` 字样
- 生成方式：以 NCE3Elite 图标为底版，擦除中央 `3` 及底部文字后重新渲染 `1` 和 `NCE 1`

---

## 5. 启动页

- `LaunchScreen.storyboard`：Oxford Blue 背景 + "NCE1 Elite" Antique Gold 文字
- `INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen`

---

## 6. 已实现功能清单

### 6.1 课程列表页（首页）
- **单一扁平列表，144 课按课号 1–144 顺序显示，不做 Unit 分组/折叠**
- 搜索：按课号或标题过滤
- 数字快速跳转栏（底部水平滚动，每 24 课一个锚点：1 / 25 / 49 / 73 / 97 / 121，共 6 个，点击自动定位）
- 每行显示：课号、标题、时长/导入状态、收藏星标、**真实播放进度条**
- **进度条**：通过 `AVURLAsset` 读取音频文件真实时长，与 SwiftData 中 `lastPlayedPosition` 计算得出百分比（0.0–1.0），已听过的课显示蓝色进度条，未听过的无进度条
- 未导入课程显示 ☁️ "需导入" + 点击弹窗引导去设置导入

### 6.2 播放页
- **播放前倒计时**：点击课程后弹出播放器，先展示 4 秒倒计时（环形动画 + 大号数字 4→3→2→1），显示课文编号和标题，下方有"立即播放"按钮可跳过倒计时。进入边听边看后返回再进入新课时，自动重置为只听模式
- 播放 / 暂停 / 上/下一课（在全书 144 课范围内循环，无 Unit 边界限制）
- 拖动进度条 + 快进/快退 15s 按钮
- 倍速播放：0.75x / 1.0x / 1.25x / 1.5x
- **循环模式**：不循环 / 单课循环 / 列表循环（使用 AVAudioPlayerDelegate 检测播放结束）
- **睡眠定时器**：15 / 30 / 45 / 60 分钟自动暂停，倒计时显示
- **边听边看模式**：只听 / 边听边看，后者显示中英双语课文全文，可调字体大小（`@AppStorage("lessonFontSize")`，13–24pt）
- 中文译文：全 144 课 AI 翻译，集成于 `lessons.json` 的 `chineseText` 字段，与英文原文逐句对应；用户可通过导入 JSON 覆盖
- 锁屏 Now Playing：显示课程标题、课号、进度，支持远程播放/暂停命令
- 后台播放：锁屏不停止，配置 `UIBackgroundModes = audio` + `AVAudioSession .playback` + `beginBackgroundTask`

### 6.3 收藏页
- 扁平列表，显示已收藏课程
- 点击直接播放
- 实时反映收藏状态

### 6.4 设置页（首页右上角 ⚙️ 进入）
- **字体大小**：13–24pt 滑杆 + 实时预览
- **显示模式**：跟随系统 / 浅色 / 深色
- **内容导入**：批量导入音频（mp3）+ 批量导入课文文本（JSON），自动按文件名匹配课号；也支持单课导入
- **导入指南**：说明获取内容的正版渠道、文件格式、导入方式、版权声明
- **隐私政策**：中英双语，内置 + `privacy.html`（可部署到 GitHub Pages）

### 6.5 内容导入系统
- `ImportService`：管理 `Documents/ImportedAudio/LessonXXX.mp3` 和 `Documents/ImportedTexts/LessonXXX.json`（XXX 为课号，具体格式以实际资源命名规则为准）
- 播放优先级：用户导入 > Bundle 内置（开发回退）
- 课文文本 JSON 格式：`{"englishText": "...", "chineseText": "..."}`
- 试听预览：`sampleLessonIDs` 控制哪些课文可从 Bundle 播放（开发阶段 = 1...144，发布时 = [1, 2]，如需调整请告知）

---

## 7. 架构详情

### 7.1 服务层 (`Services/`)

| 文件 | 职责 |
|---|---|
| `AudioPlayerService.swift` | AVAudioPlayer 封装、Now Playing、远程命令、睡眠定时器、循环模式、后台任务管理 |
| `LessonDataService.swift` | 读取 `lessons.json`，返回按课号排序的扁平数组 |
| `ImportService.swift` | 管理用户导入的音频和文本文件、检查可用性、样本课程控制、**音频时长读取与缓存**（`AVURLAsset`） |

### 7.2 ViewModel 层 (`ViewModels/`)

| 文件 | 职责 |
|---|---|
| `PlayerViewModel.swift` | 播放状态桥接 UI、**4 秒播放倒计时**（可跳过/取消）、进度持久化、边听边看切换、导入文本检查 |
| `LessonListViewModel.swift` | 课程列表加载、搜索过滤、收藏缓存（`favoriteLessonIDs: Set<Int>`）|
| `FavoritesViewModel.swift` | 收藏列表获取 |

### 7.3 数据模型 (`Models/`)

```swift
struct Lesson: Identifiable, Codable, Equatable {
    let id: Int              // 1–144
    let lessonNumber: Int     // 1–144（与 id 一致，保留用于展示格式化）
    let title: String
    let audioFileName: String // 如 "Lesson1"、"Lesson001"（以实际资源命名为准）
    var englishText: String?  // 内嵌课文（开发阶段）
    var chineseText: String?  // 内嵌中文（开发阶段）
    var durationSeconds: Double // AVAudioPlayer 回填
}

@Model final class LessonProgress {
    var lessonId: Int
    var isFavorite: Bool = false
    var lastPlayedPosition: Double = 0
    var isCompleted: Bool = false
    var lastPlayedDate: Date?
}
```

> 与第二册的关键差异：`Lesson` 模型**去掉了 `unit: Int` 字段**，因为第一册不做单元分组。`id` 范围为 1–144（vs 第二册的 1–96）。

### 7.4 视图层 (`Views/`)

| 文件 | 职责 |
|---|---|
| `RootTabView.swift` | TabView 根布局（iPhone/iPad 自适应）、设置 Sheet 管理、colorSchemeMode 控制、**全屏播放器弹窗**（使用 `fullScreenCover(item:)` + `PlayerPresentation` Identifiable 包装来避免 SwiftUI 重复弹窗 bug） |
| `LessonListView.swift` | 课程列表 + 搜索 + 快速跳转栏 + 导入拦截弹窗 |
| `LessonRowView.swift` | 单行课程展示（课号、标题、时长/导入状态、星标、进度条） |
| `FavoritesView.swift` | 收藏列表 + 空状态 + 导入拦截 |
| `PlayerView.swift` | 全屏播放页：控制栏、进度、只听/边听边看、速度、循环、睡眠定时器 |
| `SettingsView.swift` | 设置页：字体、显示模式、导入、导入指南、隐私政策 |
| `SplashView.swift` | 启动画面（渐隐过渡） |

> 与第二册的关键差异：**去掉 `UnitSectionView.swift`**（第二册用于渲染单元折叠区域），第一册不需要该组件。

### 7.5 设计系统 (`DesignSystem/`)

| 文件 | 职责 |
|---|---|
| `Colors.swift` | 静态色 + 自适应色 `Color(light:dark:)` 扩展 |
| `Typography.swift` | 字体样式方法 |
| `NCE1EliteComponents.swift` | FavoriteStarButton、LessonProgressBar、SpeedChip、NCE1Divider |

### 7.6 关键架构模式

**播放倒计时**（`PlayerViewModel`）：
- `play(lesson:)` 启动 `Task` 异步倒数 4 秒，每秒递减 `countdownSeconds`（`@Observable` 驱动 UI 更新）
- 归零后调用 `audioService.play()`，`skipCountdown()` 可立即播放，`cancelCountdown()` 在返回/切课时取消任务
- `PlayerView` 叠加 `countdownOverlay`（环形动画 + 大号数字 + 跳过按钮）

**全屏弹窗防复发**（`RootTabView`）：
- 使用 `fullScreenCover(item: $playerPresentationID)` 而非 `isPresented:`
- `PlayerPresentation` 为 `Identifiable` 包装，每次创建新 UUID，强制 SwiftUI 重新构造全屏

**真实进度条**：
- `ImportService.audioDuration(for:)` 通过 `AVURLAsset.duration` 读取音频文件头获取真实时长，结果缓存在 `[Int: Double]` 字典
- `LessonListViewModel.progress(for:)` 用 `lastPlayedPosition / audioDuration` 计算百分比

**字体大小同步**：
- 字体大小通过 `@AppStorage("lessonFontSize")` 在 SettingsView 和 PlayerViewModel 之间同步
- 注意：PlayerViewModel 不能直接使用 `@AppStorage`，需通过 `UserDefaults.standard.double(forKey:)` 读取同一 key

---

## 8. 项目文件结构

```
NCE1Elite/
├── CLAUDE.md
├── .gitignore
├── privacy.html
├── NCE1Elite.xcodeproj
├── NCE1Elite/
│   ├── NCE1EliteApp.swift                // @main，音频会话配置 + 中断处理
│   ├── Models/
│   │   ├── Lesson.swift
│   │   └── LessonProgress.swift
│   ├── ViewModels/
│   │   ├── LessonListViewModel.swift
│   │   ├── PlayerViewModel.swift
│   │   └── FavoritesViewModel.swift
│   ├── Views/
│   │   ├── RootTabView.swift
│   │   ├── LessonListView.swift
│   │   ├── LessonRowView.swift
│   │   ├── FavoritesView.swift
│   │   ├── PlayerView.swift
│   │   ├── SettingsView.swift            // 含 ImportGuideView + PrivacyPolicyView
│   │   └── SplashView.swift
│   ├── Services/
│   │   ├── AudioPlayerService.swift
│   │   ├── LessonDataService.swift
│   │   └── ImportService.swift
│   ├── DesignSystem/
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   └── NCE1EliteComponents.swift
│   ├── Resources/
│   │   ├── Audio/                        // Lesson1.mp3 – Lesson144.mp3（英音）
│   │   └── lessons.json                  // 144 课元数据 + 中英课文文本（AI 翻译中文译文，不含 durationSeconds）
│   ├── LaunchScreen.storyboard
│   ├── PrivacyInfo.xcprivacy
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/
```

---

## 9. App Store 发布注意事项

1. **提交前**：将 `ImportService.sampleLessonIDs` 从 `Set(1...144)` 改为 `[1, 2]`（假设值，如需调整试听课程范围请提前告知），删除 Bundle 中 Lesson3–144.mp3 及 `lessons.json` 中对应课的 `englishText`/`chineseText`
2. **隐私政策 URL**：`privacy.html` 需托管到公网（GitHub Pages）
3. **App Store 元数据**：描述、截图（6.7" + 6.1"）、关键词、分类（教育）
4. **版权声明**：App 描述中注明"App 不包含版权内容，用户需自行导入合法获取的学习材料"

---

## 10. 编码规范

- 所有新增类型/文件需有文档注释
- 禁止硬编码颜色 HEX 值，一律通过 `NCE1Colors` 引用
- 文字颜色用自适应 `NCE1Colors.text` / `NCE1Colors.textSecondary`，背景用 `NCE1Colors.background` / `NCE1Colors.card`
- 禁止引入第三方依赖
- 字体大小通过 `@AppStorage("lessonFontSize")` 在 SettingsView 和 PlayerViewModel 之间同步（注意：PlayerViewModel 不能直接使用 `@AppStorage`，需通过 `UserDefaults.standard.double(forKey:)` 读取同一 key）
- 提交前确保编译通过：`xcodebuild -project NCE1Elite.xcodeproj -scheme NCE1Elite -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.0' build`

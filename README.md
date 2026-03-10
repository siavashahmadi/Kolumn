# Kolumn

A native macOS Kanban board app built with SwiftUI and SwiftData. Think Trello/Monday.com, but local-first and beautifully native.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5-purple)
![SwiftData](https://img.shields.io/badge/SwiftData-1.0-green)

## Features

- **Multi-board support** — Create unlimited boards with custom names and emoji icons
- **Dynamic columns** — Add, rename, reorder, and delete columns per board (defaults: Haven't Started, In Progress, Blocked, In Review, Done)
- **Drag-and-drop** — Move task cards between columns with native macOS drag-and-drop
- **Rich task cards** — Title, priority (Low/Medium/High), due dates, tags, and notes
- **Tag system** — Create colored tags and assign them to tasks across boards
- **Theme system** — Three built-in themes: Lavender & Mint (default), Peach & Sky, Lemon & Rose
- **Local persistence** — All data stored locally via SwiftData (no cloud, no account needed)
- **Native macOS** — NavigationSplitView sidebar, proper window management, keyboard shortcuts

## Screenshots

*Coming soon*

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Kolumn.git
   ```

2. Open in Xcode:
   ```bash
   cd Kolumn
   open Kolumn.xcodeproj
   ```

3. Build and run (Cmd+R)

No dependencies. No package managers. Just open and build.

## Architecture

```
Kolumn/
├── App/                    # App entry point, global state
├── Models/                 # SwiftData @Model classes (Board, Column, TaskItem, Tag)
├── Views/
│   ├── Sidebar/            # Board list navigation
│   ├── Board/              # Kanban board with columns
│   ├── Task/               # Task cards, detail editor, quick-add
│   ├── Settings/           # App settings and theme picker
│   └── Shared/             # Reusable components (badges, chips, empty states)
├── ViewModels/             # @Observable view models
├── Theme/                  # Theme definitions, manager, and environment key
├── DragDrop/               # Transferable payload for drag-and-drop
└── Resources/              # Assets, entitlements, Info.plist
```

### Data Model

```
Board (1) ──→ (many) Column (1) ──→ (many) TaskItem
                                              ↕ (many-to-many)
                                             Tag
```

- **Board** — Has a name, emoji, sort order, and cascading columns
- **Column** — Has a title, sort order, color, and cascading tasks
- **TaskItem** — Has title, notes, due date, priority, tags, and sort order
- **Tag** — Has a name and color, shared across all tasks

### Key Patterns

- **SwiftData** for persistence — `@Model` classes with `@Relationship` for cascading deletes
- **@Observable** view models — `BoardViewModel` manages column/task CRUD for a single board
- **Environment-based theming** — `AppTheme` struct propagated via custom `EnvironmentKey`
- **Transferable drag-and-drop** — `TaskDragPayload` carries task UUID between columns

## Themes

| Theme | Background | Accent | Cards |
|-------|-----------|--------|-------|
| Lavender & Mint | `#F5F0FF` | `#C3B1E1` | `#E8F8F0` |
| Peach & Sky | `#FFF5F0` | `#FFB3A7` | `#E8F4FD` |
| Lemon & Rose | `#FFFEF0` | `#FFE066` | `#FFF0F5` |

Switch themes from **Settings > Themes** (Cmd+,). The selection persists across launches.

## Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

## License

MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

Built with SwiftUI, SwiftData, and a healthy disrespect for SaaS pricing.

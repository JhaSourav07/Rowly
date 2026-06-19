# Rowly

[![Flutter Version](https://img.shields.io/badge/Flutter-%3E%3D3.19.0-blue.svg)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-%3E%3D3.3.0-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform Support](https://img.shields.io/badge/Platform-Web%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)](#)

Rowly is a production-grade, high-performance, and visually premium cross-platform spreadsheet viewer and editor. Designed to handle large datasets effortlessly, Rowly brings the infinite grid experience of Microsoft Excel to a lightweight and modern Flutter interface. It supports opening, editing, sorting, filtering, and saving both CSV and Excel (`.xlsx`/`.xls`) files seamlessly.

---

## 🚀 Key Features

- **Infinite Grid Workspace**: Seamless virtual grid allocation supporting up to **100,000 virtual rows** and **1,000 columns** with horizontal and vertical virtualization to keep scrolling butter-smooth.
- **Bidirectional Excel Support**: Open modern and legacy Excel spreadsheets (`.xlsx`/`.xls`) directly. Modify data in Rowly and save changes straight back to the original spreadsheet file.
- **Excel-Style Column Headers**: Sticky top column header row displaying column letters (A, B, C, ..., Z, AA) and custom column names, with click-to-sort and right-click contextual column operations.
- **Dynamic Sorting & Filtering**: Instantly search across physical and mutated virtual cells. Sort grid columns in ascending/descending order on the fly.
- **Interactive Formula Bar**: Live Excel-style formula bar reflecting active cell coordinates and values, complete with full multi-line expansion support.
- **Structural Row & Column Operations**:
  - Insert rows and columns dynamically.
  - Freeze columns to keep them sticky while scrolling horizontally.
  - Rename, duplicate, delete, and hide rows/columns.
- **Dynamic Dark/Light Themes**: Beautiful, responsive themes with vibrant color accents. Toggle between dark and light modes seamlessly from the toolbar.
- **Automatic Trimming Boundaries**: Saves clean datasets back to disk by discarding trailing empty virtual cells and only keeping populated/renamed cells.

---

## 🛠️ Tech Stack & Architecture

Rowly is built using the latest modern Flutter patterns:

- **Core**: [Flutter SDK](https://flutter.dev) & [Dart](https://dart.dev).
- **State Management**: [Riverpod (v2)](https://riverpod.dev) with annotations for clean, reactive state management.
- **Code Generation**: `build_runner` and `riverpod_generator`.
- **Excel Processing**: Bidirectional translation using the lightweight `excel` library.
- **Clean Architecture**: Structured with clear layer boundaries:
  - **Data Layer**: Access and translate files (CSV parser, Excel translator, local file reading/writing).
  - **Domain Layer**: Core data models (Spreadsheet Metadata, Cell Positions, Table Selections).
  - **Presentation / State Layer**: Riverpod notifier providers for business logic (Table Filters, Column Operations, Editing Mutations, Theme Mode).
  - **UI / Widget Layer**: Fully virtualized grid and toolbar components.

---

## 📂 Repository Structure

```
lib/
├── app/
│   └── theme/
│       ├── colors.dart         # Dynamic Light/Dark mode theme tokens
│       └── typography.dart     # Consistent typography rules
├── features/
│   └── csv_workspace/
│       ├── data/
│       │   ├── datasources/    # File IO and Excel conversion core
│       │   └── repositories/   # Data sync implementations
│       ├── domain/
│       │   ├── models/         # Core business entities (cells, metadata)
│       │   └── repositories/   # Contract definitions for data layers
│       └── presentation/
│           ├── controllers/    # Riverpod state managers (filter, editing)
│           └── widgets/        # Virtual Grid, Sidebar, Toolbars, context menus
├── shared/
│   └── extensions/             # Context and theme extensions
└── main.dart                   # Root app setup and theme injection
```

---

## 🏁 Getting Started

### 📋 Prerequisites

To run Rowly locally, ensure you have installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.19.0`)
- [Dart SDK](https://dart.dev/get-started) (`>= 3.3.0`)

### ⚙️ Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/JhaSourav07/Rowly.git
   cd Rowly
   ```

2. **Get dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Code Generation**:
   Since Rowly relies on Riverpod annotations for state management, generate the required `.g.dart` files:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Launch the application**:
   - **For Web**:
     ```bash
     flutter run -d chrome
     ```
   - **For Desktop (Linux/Windows/macOS)**:
     ```bash
     flutter run -d linux # or windows/macos
     ```

---

## 🧪 Testing

Rowly includes a comprehensive unit and widget testing suite ensuring core features like keyboard navigation, file saving boundaries, Excel conversion, and filtering remain solid.

Run all tests:
```bash
flutter test
```

Key test suites:
- `test/excel_converter_test.dart`: Validates bidirectional `.xlsx`/`.xls` parsing and conversion.
- `test/keyboard_navigation_test.dart`: Asserts spreadsheet grid arrow key selection offsets and boundary scrolling.
- `test/save_changes_test.dart`: Verifies visual-to-physical trimming bounds on CSV/Excel save.
- `test/theme_test.dart`: Verifies dynamic theme toggling and reactive color updates.

---

## 🤝 Contributing

Contributions are welcome! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) guide to understand our branching conventions, commit guidelines, and pull request workflow.

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

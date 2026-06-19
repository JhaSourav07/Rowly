# Contributing to Rowly

Thank you for your interest in contributing to Rowly! We welcome contributions of all forms—bug fixes, feature implementations, optimization, documentation updates, and translations.

Following these guidelines helps ensure a smooth, efficient, and friendly contribution process for everyone.

---

## 🤝 Code of Conduct

By participating in this project, you agree to maintain a respectful, welcoming, and harassment-free environment for all contributors. Please communicate constructively and focus on collaboration.

---

## 🐛 How to Help

### Reporting Bugs
If you find a bug:
1. Search the existing issues to see if it has already been reported.
2. If it is new, open a new issue.
3. Provide a clear title, description of the bug, steps to reproduce, expected behavior, and screenshots or logs (if applicable).

### Suggesting Enhancements
We welcome feedback and new feature suggestions:
1. Search existing issues to verify it hasn't been proposed yet.
2. Open a new issue with the tag `enhancement`.
3. Explain why the feature is useful and how it should work.

---

## 💻 Development Workflow

### 1. Fork and Clone
1. Fork the Rowly repository to your own GitHub account.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Rowly.git
   cd Rowly
   ```
3. Add the main repository as an upstream remote:
   ```bash
   git remote add upstream https://github.com/JhaSourav07/Rowly.git
   ```

### 2. Branching Strategy
Create a descriptive feature branch from the latest `main` branch before making changes:
```bash
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name  # or bugfix/your-bugfix-name
```

### 3. Code Generation & Analysis
Since Rowly utilizes Riverpod code generation, compile all dynamic providers as you make changes:
```bash
# Keep build runner running reactively in the background
dart run build_runner watch --delete-conflicting-outputs

# Or build once
dart run build_runner build --delete-conflicting-outputs
```

Before committing, run the static analyzer to make sure there are no warnings or errors:
```bash
flutter analyze
```

### 4. Writing & Running Tests
Ensure your code changes are backed by testing, especially for core logic, repositories, and state managers.
- Place tests in the `test/` directory.
- Run the full test suite to confirm everything passes:
  ```bash
  flutter test
  ```

---

## 📝 Commit Message Guidelines

We recommend using **Conventional Commits** to keep git history readable, clean, and easily parseable:

Format: `<type>(<scope>): <subject>`

- **feat**: A new feature (e.g. `feat(theme): add light mode toggle support`)
- **fix**: A bug fix (e.g. `fix(grid): resolve keyboard navigation offset boundaries`)
- **docs**: Documentation updates (e.g. `docs(readme): update build instructions`)
- **style**: Changes that do not affect the meaning of the code (formatting, missing semi-colons, etc.)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **test**: Adding missing tests or correcting existing tests
- **chore**: Build tasks, package updates, or CI workflow changes

---

## 🚀 Pull Request Checklist

Before submitting a Pull Request, please ensure you can check off the following:

- [ ] Your branch is up to date with the upstream `main` branch.
- [ ] Code compiles without errors.
- [ ] `flutter analyze` reports zero issues (warnings or errors).
- [ ] All existing and new unit/widget tests pass successfully via `flutter test`.
- [ ] The build runner generated files (`.g.dart`) are fully committed.
- [ ] Your commit messages follow the commit style guidelines.
- [ ] If your changes affect the UI, include screenshots or GIFs in your PR description.

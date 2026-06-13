# AGENTS.md

## Project Overview

Personal finance Flutter app for Android. Tracks accounts, transactions, categories, budgets with multi-currency support, biometric auth, and haptic feedback.

## Stack

- **Flutter** — UI framework
- **Riverpod** — state management (per-feature `provider.dart` files)
- **Drift** — local database (code generation via `.g.dart`)
- **Feature-first architecture**

## Project Structure

```
lib/
├── app/            # App root, router, theme
├── core/           # Constants, l10n, core services, utils
├── data/           # Database schema, repositories
├── features/       # Feature modules (provider + screen + widgets)
├── shared/         # Cross-feature models, providers, services, widgets
└── main.dart
```

### Layer Responsibilities

**`core/`** — app-wide infrastructure. No business logic.
- `constants.dart` — global constants
- `l10n/` — localization strings and locale provider
- `services/` — biometric, haptic, card color services
- `utils/result.dart` — `Result<T>` type for error handling

**`data/`** — persistence only. No UI, no Riverpod providers.
- `database/` — Drift tables and generated code. Do not edit `.g.dart` files manually.
- `repositories/` — `AccountRepository`, `TransactionRepository`. All DB access goes through repositories.

**`features/<name>/`** — self-contained feature modules.
- `provider.dart` — Riverpod providers scoped to this feature
- `screen.dart` — top-level screen widget, minimal logic
- `widgets/` — feature-specific widgets

**`shared/`** — reusable across features.
- `models/` — `Account`, `Transaction` data classes
- `providers/` — providers used by multiple features
- `services/` — `ExchangeRateService`, `StorageService`
- `utils/` — `CurrencyUtils`
- `widgets/` — `BynSign`, `ErrorSnackbar`

## Architecture Rules

- Widgets never access repositories directly — always through providers
- Providers in `features/<name>/provider.dart` are local to that feature
- Providers in `shared/providers/` are app-wide
- Business logic lives in providers or repositories, not in widgets or screens
- `Result<T>` from `core/utils/result.dart` is used for fallible operations in repositories
- Database queries are in repositories only — no raw Drift queries in providers or widgets
- After any changes to Drift tables or DAOs, run `dart run build_runner build --delete-conflicting-outputs`

## Code Style

**No comments anywhere in the codebase.** No `//`, no `/* */`, no `///` doc comments. Code must be self-explanatory through naming.

- Use descriptive names — no abbreviations unless universally known (`id`, `url`, `db`)
- Prefer named constructors and named parameters
- Extract widgets aggressively — if a build method exceeds ~40 lines, split it
- Widget files: one primary widget per file, name matches filename
- Use `final` everywhere possible
- No `dynamic` types
- Avoid `late` unless genuinely necessary

## Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `balance_card.dart` |
| Classes | `PascalCase` | `BalanceCard` |
| Providers | `camelCase` + `Provider` suffix | `transactionListProvider` |
| Riverpod notifiers | `PascalCase` + `Notifier` suffix | `AddTransactionNotifier` |
| Private members | `_camelCase` | `_handleSubmit` |

## Feature Structure Template

When adding a new feature, follow this pattern:

```
features/
└── <feature_name>/
    ├── provider.dart   # Riverpod providers for this feature
    ├── screen.dart     # Top-level screen widget
    └── widgets/        # Sub-widgets (create only if needed)
```

## Key Patterns

**Error handling** — use `Result<T>`:
```dart
final result = await repository.getAccounts();
result.when(
  success: (accounts) => ...,
  failure: (error) => ...,
);
```

**Localization** — use `AppStrings` from `core/l10n/app_strings.dart`, never hardcode strings visible to the user.

**Currency formatting** — use `CurrencyUtils` and `amountFormatProvider`, never format amounts manually.

**Haptics** — route all haptic feedback through `HapticService`, never call `HapticFeedback` directly.

**Colors for accounts** — use `CardColorService`, not hardcoded colors.

## Existing Features

- **dashboard** — main screen with account carousel (`BalanceCard`), transaction list, search, filter chips, budget progress, account editor overlay
- **add_transaction** — form screen: amount input, type toggle (income/expense), category picker, currency picker, account selector, date/time pickers, note field
- **categories** — category list management
- **settings** — theme, language, currency, budget, amount format, card text color, haptics, currency conversions

## What NOT to Do

- Do not add comments
- Do not put business logic in screen or widget files
- Do not access `AppDatabase` directly from features — use repositories
- Do not create new providers in `shared/providers/` unless the provider is needed by 2+ features
- Do not use `BuildContext` across async gaps without checking `mounted`
- Do not hardcode user-facing strings — use `AppStrings`
- Do not format currency amounts manually — use `CurrencyUtils`
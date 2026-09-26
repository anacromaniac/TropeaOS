# Project Instructions

TropeaOS is a fork of **OnionOS**, a custom operating system for the Miyoo Mini / Mini Plus
retro handhelds. It is written almost entirely in C and cross-compiled for ARM
(`PLATFORM=miyoomini`) using a Docker toolchain. `main` and `bootstrap` currently point at the
same commit (a clean OnionOS fork); no Tropea-specific code exists yet.

## Tech Stack
- **Language**: C (gnu18) + a little C++17 (the GoogleTest suite)
- **UI / graphics**: SDL 1.2 (`-lSDL`, `-lSDL_ttf`, `-lSDL_image`, `-lSDL_rotozoom`)
- **Data**: cJSON (vendored `include/cjson`), sqlite3 (vendored + shared lib)
- **IPC/state**: shared memory vars (`libshmvar`), UDP, flag files under `/tmp`
- **Build**: recursive `make` from the root Makefile, ARM cross-compiler
- **Tests**: GoogleTest + cppcheck static analysis

## Code Style
- Format with **clang-format** (`make format`, config in `.clang-format`: LLVM base,
  Stroustrup braces, 4-space indent, no tabs, no column limit). CI auto-formats PRs.
- Naming: `snake_case` for functions/vars, `PascalCase` for structs/typedefs,
  `UPPER_SNAKE_CASE` for macros/constants. Headers use `#ifndef NAME_H__` guards.
- Most shared code lives as `static` inline functions in headers under `src/common/`
  (e.g. `system/`, `theme/`, `utils/`). Prefer reusing these over new helpers.
- Errors are handled with return-value checks / boolean helpers and `log_*` macros,
  not exceptions.

## Testing
- Run tests: `make test` (requires libgtest; see `.github/workflows/test.yml` for setup)
- Static analysis: `make static-analysis` (cppcheck)
- Test pattern: `test/test_*.cpp` using GoogleTest fixtures; test data in
  `test/<name>_test_data/`. Only `infoPanel` is currently covered.

## Build & Run
- Full build: `make build` (validate with `make build`, not incremental single dirs)
- Release zip: `make release`
- Clean: `make clean` / `make deepclean`
- In toolchain (no local cross-compiler): `make with-toolchain CMD="build"`
- Lint / format: `make format`
- There is no local "run" — output is packaged into `dist/` for the SD card.

## Project Structure
- `src/` — one directory per system binary (`keymon`, `gameSwitcher`, `infoPanel`, …);
  each has its own `Makefile` including `src/common/config.mk`.
- `src/common/` — shared headers: `system/` (device, settings, state), `theme/`
  (rendering/loading), `utils/` (file, log, str, udp), `components/`.
- `include/` — vendored third-party headers/sources (cJSON, sqlite3, SDL rotozoom, gfx, png).
- `lib/` — prebuilt ARM `.so` libraries shipped to the device.
- `static/build/.tmp_update/` — the runtime that lands on the SD card: `runtime.sh` is the
  boot entry, plus `script/` helpers and `bin/` binaries.
- `static/configs/`, `static/packages/` — default configs and bundled app/emulator packages.
- `third-party/` — git submodules (RetroArch-patch, SearchFilter, Terminal, DinguxCommander).
- `test/`, `website/` — GoogleTest suite; Docusaurus documentation site.
- `.github/workflows/` — `build.yml` (toolchain build check), `test.yml` (gtest + cppcheck),
  `format.yml` (auto clang-format on PRs).

## Conventions
- **Commit messages: use Conventional Commits** — `type(scope): summary`, e.g.
  `ci: make workflows fork-agnostic`, `docs: add AGENTS.md`, `fix(keymon): suspend logic`.
  Use `feat`, `fix`, `ci`, `docs`, `refactor`, `test`, `chore`; short imperative summary.
  (Upstream OnionOS used plain subjects with PR numbers; TropeaOS uses Conventional Commits.)
- CI branch: PRs target `main` (workflows run on `pull_request`/`merge_group`).
  Merge method is chosen case by case: **squash** for iterative/multi-commit PRs where the
  history is noise (yields one clean entry), **rebase** when the commits are already clean
  and individually meaningful. Don't default to a single method.
- Onion-coupled identity is being phased out: workflows read the toolchain image from the
  `TOOLCHAIN_IMAGE` repo Variable (default/fallback: the TropeaOS GHCR image), and theme
  downloads default to the `anacromaniac/TropeaOS-Themes` fork via `THEMES_REPO`.

- Theme downloads are **non-blocking** by default (a failure degrades to "no themes").
  Release workflows set `THEMES_STRICT=1`, which makes theme fetch failures abort the build.
- Runtime config is read from `/mnt/SDCARD/.tmp_update/config/`; transient flags live in `/tmp`.
- Device model is detected at boot (`DEVICE_ID` 283 = Mini, 354 = Mini Plus); branch on it
  where hardware differs.

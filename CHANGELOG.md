## [Unreleased]

## [0.3.11] - 2026-08-09

### Added
- Commit message detail level, chosen with `aicm -d` / `aicm --detail` and stored as `commit_detail` in `config.yml`: `concise` keeps the current subject-only message, `detailed` adds an explanatory paragraph and a bullet list of notable changes
- `aicm --help` shows the configured detail level

### Changed
- The `Edit` action now opens the generated message in your editor via `git commit -e`, honouring `GIT_EDITOR`/`core.editor`/`VISUAL`/`EDITOR`, instead of asking for a single line of input

### Fixed
- `git commit` no longer goes through the shell, so a message containing backticks, quotes or `$` is committed verbatim instead of being expanded or truncated

## [0.3.10] - 2026-08-09

### Added
- Presets can declare a built-in model list, offered directly during setup with no detection request
- Built-in model list for AMD Radeon (China), whose gateway always answers `/models` with 403
- Presets can record each model's context window; setup reports it and suggests a matching `diff_len` instead of always defaulting to 32768

### Fixed
- Crash (`undefined method 'empty?' for nil`) when pressing Enter at the API key prompt to keep the existing key

## [0.3.9] - 2026-08-08

### Added
- The model list fetch timeout is now configurable: `aicm setup` asks for it as its first step and stores it as `model_fetch_timeout` in `config.yml`, applying to `aicm -p` and `aicm -m` as well
- `aicm --help` shows the configured timeout

## [0.3.8] - 2026-08-08

### Changed
- Increased the model list fetch timeout from 5s to 30s, so slower providers can finish responding during setup

## [0.3.7] - 2026-08-08

### Added
- AMD Radeon (China) provider preset (`https://developer.amd.com.cn/radeon/api/v1`), an OpenAI-compatible endpoint
- README section for AMD Radeon with the token factory registration link and available models
- README section for Apple Local Models via `apple-to-openai`

### Fixed
- `ConfigManager.update_provider` silently dropped writes for providers missing from an existing `config.yml`; newly added presets are now appended with their default `base_url`

## [0.3.6] - 2026-02-27

### Changed
- Optimized commit message synthesis logic
- Renamed `commit_ai_no_model` for clarity

### Fixed
- Corrected the "no changes" message display

## [0.3.5] - 2026-02-04

### Added
- Commit message format option: `simple`, `conventional` and `gitmoji`

### Fixed
- Release script corrections and Homebrew formula update for v0.3.4

## [0.3.4] - 2026-01-30

### Added
- Anthropic Claude and NVIDIA NIM provider presets; provider list reordered

### Changed
- Extracted diff handling into a new `DiffHelpers` module
- Improved CLI UX with better padding and formatting

## [0.3.3] - 2026-01-28

### Changed
- Modernized configuration handling and quote style
- Updated dependencies
- Added release prep and publish guides

## [0.3.2] - 2026-01-28

### Fixed
- Crash caused by the color helper method

## [0.3.1] - 2026-01-28

### Fixed
- Gemspec executable path so the Homebrew tarball build works
- Executable name in the Homebrew formula

## [0.3.0] - 2026-01-28

### Added
- YAML configuration system (`~/.config/commitgpt/`) with multi-provider support
- Homebrew distribution via `brew tap`
- Streaming responses and improved error handling
- Clean working tree check
- Interactive prompt to stage all changes when the diff is empty

### Fixed
- Ctrl+C interrupt handling

## [0.2.0] - 2026-01-09

### Added
- Custom API endpoint support and model listing
- Alternative response field support for non-OpenAI providers

### Changed
- Improved API error handling

## [0.1.2] - 2023-02-15

- Documentation updates

## [0.1.1] - 2023-02-15

- Maintenance release

## [0.1.0] - 2023-02-14

- Initial release

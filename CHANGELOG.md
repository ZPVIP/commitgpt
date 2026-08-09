## [Unreleased]

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

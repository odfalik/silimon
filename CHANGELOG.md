# Changelog

## [0.8.3](https://github.com/odfalik/silimon/compare/v0.8.2...v0.8.3) (2026-01-04)


### Bug Fixes

* update banner shows full brew update command ([7bc73ae](https://github.com/odfalik/silimon/commit/7bc73ae98f08fb7cc855d4a2cb29e591b5acff33))

## [0.8.2](https://github.com/odfalik/silimon/compare/v0.8.1...v0.8.2) (2026-01-04)


### Features

* kill existing silimon instances on startup ([0be883a](https://github.com/odfalik/silimon/commit/0be883a64db60255c3f915ca13a983bd6eda26f5))

## [0.8.1](https://github.com/odfalik/silimon/compare/v0.8.0...v0.8.1) (2026-01-04)


### Bug Fixes

* add explicit version to homebrew formula in CI ([e3a8de7](https://github.com/odfalik/silimon/commit/e3a8de7ecb50260ee0070e73fddd24f768971a31))
* resolve executable path correctly for daemonization ([06bbdf6](https://github.com/odfalik/silimon/commit/06bbdf6d17d23ec0b41217df4bafda1408f4fc16))

## [0.8.0](https://github.com/odfalik/silimon/compare/v0.7.2...v0.8.0) (2026-01-03)


### Features

* add configurable history duration slider (30s to 5 minutes)
* add custom color picker with curated color palette for each metric
* add sparkline width options (narrow, medium, wide)
* add confirmation dialogs for Reset and Quit buttons


### Bug Fixes

* fix export button height to match other buttons
* fix CPU frequency parsing (kHz not Hz)
* fix notification API crash when running without app bundle
* fix Y-scale mismatch between menu bar sparkline and popover charts


### Performance

* remove 60fps TimelineView animations causing unnecessary CPU usage
* add Metal-accelerated chart rendering with .drawingGroup()
* reduce chart samples from 60 to 30 for smoother updates


### Defaults

* change default mode to graph (sparkline) instead of text
* show GPU, CPU, Memory in menu bar by default
* set default history duration to 60 seconds

## [0.7.2](https://github.com/odfalik/silimon/compare/v0.7.1...v0.7.2) (2026-01-03)


### Features

* comprehensive improvements batch ([#17](https://github.com/odfalik/silimon/issues/17)) ([b22dbd7](https://github.com/odfalik/silimon/commit/b22dbd7f2b736b79bc339c97bdcd0fb106395e6c))

## [0.7.1](https://github.com/odfalik/silimon/compare/v0.7.0...v0.7.1) (2026-01-03)


### Bug Fixes

* correct release-please extra-files config for version annotation ([a8cfa9f](https://github.com/odfalik/silimon/commit/a8cfa9f67f0848a2c9cc02dad6a78d83b3441a26))
* explicitly reference release-please config files in workflow ([b20b0b1](https://github.com/odfalik/silimon/commit/b20b0b1e123bc6e0c4c5a954e42ff7fac30c7a20))

## [0.7.0](https://github.com/odfalik/silimon/compare/v0.6.0...v0.7.0) (2026-01-03)


### Features

* add release workflow skill and cleanup redundant checks ([543a52f](https://github.com/odfalik/silimon/commit/543a52f85a3f301bcf3e4b4bdf831918f6f28a04))


### Bug Fixes

* repair release workflow YAML syntax ([f085a7a](https://github.com/odfalik/silimon/commit/f085a7af99848e70a9e3bbbc2614b538c12519a1))

## [0.6.0](https://github.com/odfalik/silimon/compare/v0.5.1...v0.6.0) (2026-01-03)


### Features

* add in-app diagnostics and install compatibility checks ([#14](https://github.com/odfalik/silimon/issues/14)) ([9617c9a](https://github.com/odfalik/silimon/commit/9617c9aa1affb7d02354dee7c040706b9ab0306b))
* add menu bar graph mode with overlaid sparklines ([4ee087a](https://github.com/odfalik/silimon/commit/4ee087a9fb9d2b847c9558df7b5d2641fbeef385))
* add network throughput monitoring ([f597351](https://github.com/odfalik/silimon/commit/f59735128030fe1700a2160d89f3a166e6c8d7e8))


### Bug Fixes

* explicit error handling in update checker ([5acd3f9](https://github.com/odfalik/silimon/commit/5acd3f9ee90e27248cd6c121b17f6290f7243ec8))

## [0.5.1](https://github.com/odfalik/silimon/compare/v0.5.0...v0.5.1) (2026-01-03)


### Bug Fixes

* GPU metrics not working on M3/M4 chips ([da7d83e](https://github.com/odfalik/silimon/commit/da7d83e44435a6f86a3a34d5a307e3dcc38724f6))
* ignore terminal signals for robust backgrounding ([08adaf9](https://github.com/odfalik/silimon/commit/08adaf9f5adf6c3a93a4d0968ff8222d7138c760))

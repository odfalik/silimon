# Changelog

## [0.5.0](https://github.com/odfalik/silimon/compare/v0.4.0...v0.5.0) (2026-01-03)


### Features

* add tooltips to memory pressure indicator and swap ([8927324](https://github.com/odfalik/silimon/commit/89273241f0d73c8c517bd2f4d7370bbe3ff457fc))


### Bug Fixes

* use native NSView tooltips that work in popovers ([ee3572d](https://github.com/odfalik/silimon/commit/ee3572d4346ba0c3a3c895f50fb8a0cf62fd064e))
* use NSHostingView wrapper for working tooltips ([7e06654](https://github.com/odfalik/silimon/commit/7e0665437ad518d21f8296e014b72a61abda9a70))

## [0.3.0](https://github.com/odfalik/silimon/compare/v0.2.0...v0.3.0) (2026-01-03)


### Features

* add settings panel and fix powermetrics parsing ([#2](https://github.com/odfalik/silimon/issues/2)) ([46e32e1](https://github.com/odfalik/silimon/commit/46e32e11cb23a2594e11c212e77c7d39cdbecf75))
* drag-and-drop ordering and pill toggle controls ([#5](https://github.com/odfalik/silimon/issues/5)) ([deadfcf](https://github.com/odfalik/silimon/commit/deadfcf50d7cb1181c7e07fc4fa2ed4d5cdb9153))
* redesigned menu bar with colored fill indicators and improved settings ([#4](https://github.com/odfalik/silimon/issues/4)) ([97dc185](https://github.com/odfalik/silimon/commit/97dc18514de410bd78b0a8aed08ac862b171f5a9))

## [0.2.0](https://github.com/odfalik/silimon/compare/v0.1.0...v0.2.0) (2026-01-03)


### Features

* add automated releases with release-please ([8496d03](https://github.com/odfalik/silimon/commit/8496d03932da6634432e906e36c4fc3769983996))

## [0.1.0](https://github.com/odfalik/silimon/releases/tag/v0.1.0) (2025-01-03)

### Features

* Initial release of Silimon
* Real-time power consumption monitoring (CPU, GPU, ANE in watts)
* CPU cluster frequencies (E-cores vs P-cores in MHz)
* GPU utilization and frequency
* Memory usage with pressure indicators
* Thermal state monitoring
* Sparkline charts for all metrics
* Menu bar integration with compact popover UI

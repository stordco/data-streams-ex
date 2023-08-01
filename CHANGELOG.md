# Changelog

## [1.2.1](https://github.com/stordco/data-streams-ex/compare/v1.2.0...v1.2.1) (2023-08-01)


### Miscellaneous

* Add elixir 1.15 to CI tests ([#21](https://github.com/stordco/data-streams-ex/issues/21)) ([d43b381](https://github.com/stordco/data-streams-ex/commit/d43b3817e7154bfb1e7f23f913343afc2d44f76c))
* Migrate to internal FNV module ([#22](https://github.com/stordco/data-streams-ex/issues/22)) ([e3f6f91](https://github.com/stordco/data-streams-ex/commit/e3f6f9117b1d64d7db4288b79bba36fbbecaa80d))
* Setup common config elixir ([180752d](https://github.com/stordco/data-streams-ex/commit/180752d5056e8bfff254809b78a33f3c24ef5d0e))
* Sync files with stordco/common-config-elixir ([#23](https://github.com/stordco/data-streams-ex/issues/23)) ([a1360fd](https://github.com/stordco/data-streams-ex/commit/a1360fdcd28fbb1f908210b386f706f4adfde438))

## [1.2.0](https://github.com/stordco/data-streams-ex/compare/v1.1.2...v1.2.0) (2023-07-10)


### Features

* allow tracking kafka produce and consume offsets ([#18](https://github.com/stordco/data-streams-ex/issues/18)) ([ebab69b](https://github.com/stordco/data-streams-ex/commit/ebab69bb896eddb23913a49098ebc3460e4ae72c))

## [1.1.2](https://github.com/stordco/data-streams-ex/compare/v1.1.1...v1.1.2) (2023-06-05)


### Bug Fixes

* defensive code around container logic ([#16](https://github.com/stordco/data-streams-ex/issues/16)) ([97d770b](https://github.com/stordco/data-streams-ex/commit/97d770b0db652f6a202bdafb812321ea55799592))

## [1.1.1](https://github.com/stordco/data-streams-ex/compare/v1.1.0...v1.1.1) (2023-06-05)


### Bug Fixes

* set span attribute to pathway hash ([#14](https://github.com/stordco/data-streams-ex/issues/14)) ([94ca3fd](https://github.com/stordco/data-streams-ex/commit/94ca3fd02f7afa4434664463bc8b257020f48243))

## [1.1.0](https://github.com/stordco/data-streams-ex/compare/v1.0.0...v1.1.0) (2023-05-23)


### Features

* add container id to transport headers ([#12](https://github.com/stordco/data-streams-ex/issues/12)) ([4d58826](https://github.com/stordco/data-streams-ex/commit/4d588260c559babbbd8635ca9b8d8261d4541d61))

## 1.0.0 (2023-04-06)


### ⚠ BREAKING CHANGES

* Package and application configuration is now under `data_streams` instead of `dd_data_streams`

### Features

* add basic implementation of ddsketch ([#1](https://github.com/stordco/data-streams-ex/issues/1)) ([125b5ed](https://github.com/stordco/data-streams-ex/commit/125b5ed57fb3b407406339d050121ff052aabf4a))
* add basic kafka tracking support with data streams ([#3](https://github.com/stordco/data-streams-ex/issues/3)) ([bfc6a0b](https://github.com/stordco/data-streams-ex/commit/bfc6a0b88879c8469760a521e5e0408d617e6918))
* add LICENSE file ([#11](https://github.com/stordco/data-streams-ex/issues/11)) ([6c5668f](https://github.com/stordco/data-streams-ex/commit/6c5668f612e89204a05e03f998a655324b2b6d8d))
* link open telemetry span to current pathway context ([#5](https://github.com/stordco/data-streams-ex/issues/5)) ([e0ed9b2](https://github.com/stordco/data-streams-ex/commit/e0ed9b22b920c12e11684fc5eef9e619eb05a1aa))
* rename dd_data_streams to data_streams ([#9](https://github.com/stordco/data-streams-ex/issues/9)) ([a0d1742](https://github.com/stordco/data-streams-ex/commit/a0d1742f9a51e45608fde92918a4c1b6c777cf9d))


### Bug Fixes

* add case for error http status ([#8](https://github.com/stordco/data-streams-ex/issues/8)) ([ef4a95d](https://github.com/stordco/data-streams-ex/commit/ef4a95dea09a644c9d90079a96d2f2683b8c6aa5))
* **ci:** update PR title regex check ([64ef99f](https://github.com/stordco/data-streams-ex/commit/64ef99fa5e8c4674debb43242307019600cc3060))
* dialyzer warnings for kafka integration map ([18bf936](https://github.com/stordco/data-streams-ex/commit/18bf936c1249360042a4d3e1434bf0a94236ed0b))
* filter out nil values from kafka integration tags ([b33926f](https://github.com/stordco/data-streams-ex/commit/b33926f584869165c0340fe06bf088813c80fda7))
* update kafka integration to not set context on produce ([#7](https://github.com/stordco/data-streams-ex/issues/7)) ([6807b6d](https://github.com/stordco/data-streams-ex/commit/6807b6dcd1f0504179e24ad78062c4484b4fe2c3))
* update otel resource service configuration ([adb9890](https://github.com/stordco/data-streams-ex/commit/adb9890f19dd49b2d3b1a4da6e00bf6d5f6823da))
* update tag logic to be more consistant ([#4](https://github.com/stordco/data-streams-ex/issues/4)) ([48d13df](https://github.com/stordco/data-streams-ex/commit/48d13dfa5634f24a83eba2e3b0a9a09adbced4a4))

## Changelog

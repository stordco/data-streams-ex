# Changelog

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

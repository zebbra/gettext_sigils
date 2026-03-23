# Changelog

## [0.3.1](https://github.com/zebbra/gettext_sigils/compare/v0.3.0...v0.3.1) (2026-03-23)


### Features

* deprecate separator-based pluralization in favor of shared message ([80ccd68](https://github.com/zebbra/gettext_sigils/commit/80ccd68fc99c6930b1a859ee466713d0f7faab64))
* deprecate separator-based pluralization in favor of shared message ([e983f23](https://github.com/zebbra/gettext_sigils/commit/e983f23df81d654c5d3369c3f88ab1cbe3829ba5)), closes [#20](https://github.com/zebbra/gettext_sigils/issues/20)

## [0.3.0](https://github.com/zebbra/gettext_sigils/compare/v0.2.1...v0.3.0) (2026-03-19)


### ⚠ BREAKING CHANGES

* require N modifier for pluralization

### Features

* add pluralization support ([71019fd](https://github.com/zebbra/gettext_sigils/commit/71019fd6a182dbf8c83afee61b4bd4def02bd726))
* require N modifier for pluralization ([84a2cff](https://github.com/zebbra/gettext_sigils/commit/84a2cff1c0e59f36ba49dd8f7f499b74224b3a18))
* update usage rules and skill with pluralization ([a686349](https://github.com/zebbra/gettext_sigils/commit/a686349a3fe276ed540422891c7b65f8380900cb))
* use || (double pipe) as default separator ([90c0d2b](https://github.com/zebbra/gettext_sigils/commit/90c0d2b9df3fd1e18b9c7073435eeaecf61bc5d9))

## [0.2.1](https://github.com/zebbra/gettext_sigils/compare/v0.2.0...v0.2.1) (2026-03-17)


### Features

* add `mix gettext_sigils.install` igniter task ([ec7975a](https://github.com/zebbra/gettext_sigils/commit/ec7975aaa53780ef61306588ec4be897ad04721d))
* add `mix gettext_sigils.install` igniter task ([b2f55ec](https://github.com/zebbra/gettext_sigils/commit/b2f55ec590ca1fb7ce0276171b4d7f38252da000)), closes [#14](https://github.com/zebbra/gettext_sigils/issues/14)
* add usage rules and localization skill for LLM agents ([8af463c](https://github.com/zebbra/gettext_sigils/commit/8af463c0969312769fbe4cd18f1acb4118b34d69)), closes [#13](https://github.com/zebbra/gettext_sigils/issues/13)

## [0.2.0](https://github.com/zebbra/gettext_sigils/compare/v0.1.1...v0.2.0) (2026-03-14)


### ⚠ BREAKING CHANGES

* replace AmbiguousInterpolationError with ArgumentError
* duplicate keys with different values now raise instead of being auto-suffixed

### Features

* raise on ambiguous interpolation keys instead of auto-suffixing ([ce7096f](https://github.com/zebbra/gettext_sigils/commit/ce7096f3fc935d7f7120bfe3419e2fd10dad7dcc))


### Code Refactoring

* replace AmbiguousInterpolationError with ArgumentError ([983ce67](https://github.com/zebbra/gettext_sigils/commit/983ce67041dc87874163b171a8cd0e68cdf576d5))

## [0.1.1](https://github.com/zebbra/gettext_sigils/compare/v0.1.0...v0.1.1) (2026-03-09)


### Features

* basic features working ([b29f420](https://github.com/zebbra/gettext_sigils/commit/b29f4207057f7232b44b1e2e698882bf7f057298))
* deduplicate binding keys ([e49efb3](https://github.com/zebbra/gettext_sigils/commit/e49efb347663df014baa9d9cda7a11d7ca4aeed7))
* resolve domain/context from sigil modifiers ([6981d7a](https://github.com/zebbra/gettext_sigils/commit/6981d7a551f252427d1290b6e7eeacb866126488))
* validate modifier definitions at use time ([4b77cbe](https://github.com/zebbra/gettext_sigils/commit/4b77cbe5ebf48d59f45f3fcad43fc8cbf4060a47))


### Bug Fixes

* use fallback for operators ([c894179](https://github.com/zebbra/gettext_sigils/commit/c894179d0fe5879a1da5dcf6e2217c1b4b7d3668))
* validate all options ([a7783f7](https://github.com/zebbra/gettext_sigils/commit/a7783f78b2d5a3f1a8fdf3e32d0e1ecdf9a97252))
* validate all options ([8c7ed52](https://github.com/zebbra/gettext_sigils/commit/8c7ed52bddb7e5210a4533b79ad809e45c3a0c56))

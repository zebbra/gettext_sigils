# Changelog

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

[![CI](https://github.com/zebbra/gettext_sigils/actions/workflows/ci.yml/badge.svg)](https://github.com/zebbra/gettext_sigils/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Hex version badge](https://img.shields.io/hexpm/v/gettext_sigils.svg)](https://hex.pm/packages/gettext_sigils)
[![Hexdocs badge](https://img.shields.io/badge/docs-hexdocs-purple)](https://hexdocs.pm/gettext_sigils)

# Gettext Sigils

<!-- MDOC -->

An Elixir library that provides a `~t` sigil for using [`Gettext`](https://hexdocs.pm/gettext/Gettext.html) translations with less boilerplate and improved readability:

```elixir
# before
gettext("Hello, %{name}", name: user.name)

# after
~t"Hello, #{user.name}"
```

## Installation

### Using igniter

The package provides an [igniter](https://hexdocs.pm/igniter/readme.html) install task for easy installation and setup:

```
mix igniter.install gettext_sigils
```

The installer also rewrites existing `use Gettext` calls in the project to `use GettextSigils`.

### Manually

The package can be installed by adding `gettext_sigils` to your list of dependencies in `mix.exs`:

<!-- x-release-please-start-version -->

```elixir
def deps do
  [
    {:gettext_sigils, "~> 0.5.0"}
  ]
end
```

<!-- x-release-please-end -->

## Basic Usage

To use the `~t` sigil in your module, just use `GettextSigils` instead of the default `Gettext` module (for example in `MyAppWeb.html_helpers/0` when using Phoenix):

```elixir
# replace this
use Gettext, backend: MyApp.Gettext

# with this
use GettextSigils, backend: MyApp.Gettext
```

You can then use the `~t` sigil instead of the `gettext` macro:

```elixir
~t"Hello, World!"
# same as
gettext("Hello, World!")
```

**Note:** The default Gettext macros (`gettext`, `pgettext`, `dgettext`, ...) remain available in modules that `use GettextSigils`, so you can mix and match as needed.

## Features

### Interpolation

Interpolated expressions become Gettext bindings with automatically derived keys:

```elixir
~t"The #{fruit.name} is #{color}"
# => gettext("The %{fruit_name} is %{color}", fruit_name: fruit.name, color: color)
```

See the [Interpolation guide](guides/interpolation.md) for the full key derivation rules, handling of ambiguous keys, and explicit `key = expr` syntax.

### Domain & Context

Set a default Gettext [domain](https://hexdocs.pm/gettext/Gettext.html#module-domains) and [context](https://hexdocs.pm/gettext/Gettext.html#module-contexts) per module under the `:sigils` key. Every `~t` sigil in the module then uses these by default:

```elixir
use GettextSigils,
  backend: MyApp.Gettext,
  sigils: [
    domain: "frontend",
    context: "dashboard"
  ]

~t"Welcome"   # => dpgettext(MyApp.Gettext, "frontend", "dashboard", "Welcome")
```

### Modifiers

Single-letter suffixes on the `~t` sigil tweak how a translation is produced. Define them under the `:modifiers` key: each entry maps a letter to a keyword list of `:domain` and/or `:context` overrides that apply when the sigil carries that letter.

```elixir
defmodule MyAppWeb.DashboardLive do
  use GettextSigils,
    backend: MyApp.Gettext,
    sigils: [
      domain: "frontend",
      context: inspect(__MODULE__),
      modifiers: [
        e: [domain: "errors"],
        g: [domain: :default, context: nil]
      ]
    ]

  ~t"Welcome"     # domain: "frontend", context: "MyAppWeb.DashboardLive"
  ~t"Not found"e  # domain: "errors",   context: "MyAppWeb.DashboardLive"
  ~t"Yes"g        # backend default domain, no context
  ~t"Not found"eg # backend default domain, no context (g runs after e)
end
```

Modifier entries can also point at a module for message rewriting, postprocessing, or custom pluralization. See the [Modifiers guide](guides/modifiers.md) for the full picture.

### Pluralization

The built-in `N` modifier turns a `~t` sigil into a plural Gettext call, selecting the singular or plural form at runtime based on the `count` binding:

```elixir
~t"#{count} error(s)"N
```

Pluralization requires a `count` binding key. Use an explicit binding key to bind it to any value:

```elixir
~t"#{count = length(errors)} error(s)"N
```

See the [Pluralization guide](guides/pluralization.md) for the full rules and how to write a custom pluralization modifier.

## Usage Rules

GettextSigils ships with usage rules and skills for LLM coding agents (Claude Code, Cursor, Codex, etc.) via the [`usage_rules`](https://hexdocs.pm/usage_rules) library. See the [LLM guide](guides/llm.md) for setup instructions.

## Sponsoring

Shoutout to my employer 🦓 [zebbra](https://zebbra.ch) for allowing me to make this public. Need Elixir expertise made in 🇨🇭 Switzerland? Feel free to [reach out](https://zebbra.ch/contact).

<!-- MDOC -->

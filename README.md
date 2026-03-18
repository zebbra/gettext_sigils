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

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `gettext_sigils` to your list of dependencies in `mix.exs`:

<!-- x-release-please-start-version -->

```elixir
def deps do
  [
    {:gettext_sigils, "~> 0.2.1"}
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
gettext("Hello, World")
```

**Note:** The default Gettext macros (`gettext`, `pgettext`, `dgettext`, ...) are still available if required.

## Domain & Context

Gettext [domain](https://hexdocs.pm/gettext/Gettext.html#module-domains) and [context](https://hexdocs.pm/gettext/Gettext.html#module-contexts) are provided under the `sigils` key when using the module. All other options are passed through to `use Gettext`.

```elixir
defmodule MyApp.Errors.NotFound do
  use GettextSigils,
    backend: MyApp.Gettext,
    sigils: [
      domain: "errors",
      context: inspect(__MODULE__)
    ]

  def description(path) do
    # uses domain and context from sigils options
    ~t[The file "#{path}" does not exist]

    # is equivalent to
    dpgettext(
      "errors",
      inspect(__MODULE__),
      ~s[The file "%{path}" does not exist],
      path: path
    )
  end
end
```

## Modifiers

Sigil modifiers (single lowercase letters appended to the sigil) can be used to override the domain and context on a per-translation basis. Define modifiers in the `sigils` options:

```elixir
defmodule MyApp.Frontend do
  use GettextSigils,
    backend: MyApp.Gettext,
    sigils: [
      domain: "frontend",
      modifiers: [
        e: [domain: "errors"],
        g: [domain: "default", context: nil],
        m: [context: inspect(__MODULE__)]
      ]
    ]

  def example do
    ~t"Welcome"           # domain: "frontend", context: nil
    ~t"Yes"g              # domain: "default",  context: nil
    ~t"Not found"e        # domain: "errors",   context: nil
    ~t"Hello"m            # domain: "frontend", context: "MyApp.Frontend"
    ~t"Oops"em            # domain: "errors",   context: "MyApp.Frontend"
  end
end
```

Each modifier key must be a single lowercase letter (`a`–`z`) and accepts the options `:domain` and `:context`. Using an undefined modifier results in a compile-time error.

## Interpolation

Gettext [interpolation](https://hexdocs.pm/gettext/Gettext.html#module-interpolation) works similar to regular Elixir strings. Keys are derived automatically from the expression:

```elixir
~t"The #{fruit.name} is #{color}"
# => gettext("The %{fruit_name} is %{color}", fruit_name: fruit.name, color: color)

~t"Status: #{String.upcase(status)}"
# => gettext("Status: %{string_upcase}", string_upcase: String.upcase(status))

~t"Value: #{1 + 2}"
# => gettext("Value: %{var}", var: 1 + 2)
```

Duplicate keys are allowed if they refer to the same expression. Otherwise, an ambiguous key error is raised.

```elixir
# This is allowed:
~t"#{name} is #{name}"
# => gettext("%{name} is %{name}", name: name)

# This is NOT allowed:
~t"This is invalid: #{Foo.bar()} != #{foo.bar}"
# => raises ArgumentError (foo_bar)
```

Use explicit keys to disambiguate between expressions with the same key.

### Explicit keys

Explicit keys can be used with the `::` syntax for more control to disambiguate between multiple bindings with the same key:

```elixir
~t"Order status: #{status :: order_status(resp[field])}"
# => gettext("Order status: %{status}", status: order_status(resp[field]))

~t"Valid: #{x :: Foo.bar()} != #{y :: foo_bar}"
# => gettext("Valid: %{x} != %{y}", x: Foo.bar(), y: foo_bar)
```
  
## Pluralization

Use the `‖` separator to split singular and plural forms. The `count` binding determines which form Gettext selects at runtime:

```elixir
~t"One error‖#{count} errors"
# with count = 1 => "One error"
# with count = 3 => "3 errors"
```

You can use explicit key syntax to bind `count` to an arbitrary expression:

```elixir
~t"One user‖#{count :: length(users)} users"
```

Under the hood, the sigil maps to Gettext's `dpngettext/6`:

```elixir
~t"One error‖#{count} errors"
# =>
dpngettext("default", nil, "One error", "%{count} errors", count)
```

`count` must appear as a binding in at least one of the singular or plural parts.

### Custom separator

The separator defaults to `‖` (U+2016 DOUBLE VERTICAL LINE). You can override it globally via application config or per-module:

```elixir
# Application config
config :gettext_sigils, :sigils, pluralization: [separator: "||"]

# Per-module
use GettextSigils,
  backend: MyApp.Gettext,
  sigils: [pluralization: [separator: "||"]]
```

## Usage Rules

GettextSigils ships with usage rules and skills for LLM coding agents (Claude Code, Cursor, Codex, etc.) via the [`usage_rules`](https://hexdocs.pm/usage_rules) library. See the [LLM guide](guides/llm.md) for setup instructions.

## Sponsoring

Shoutout to my employer 🦓 [zebbra](https://zebbra.ch) for allowing me to make this public. Need Elixir expertise made in 🇨🇭 Switzerland? Feel free to [reach out](https://zebbra.ch/contact).

<!-- MDOC -->

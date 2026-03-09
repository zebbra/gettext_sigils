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

```elixir
def deps do
  [
    {:gettext_sigils, "~> 0.1.0"}
  ]
end
```

## Basic Usage

To use the `~t` sigil in your module, just use `GettextSigils` instead of the default `Gettext` module:

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
    ~t"Not found"e        # domain: "errors",   context: nil
    ~t"Hello"m            # domain: "frontend", context: "MyApp.Frontend"
    ~t"Oops"em            # domain: "errors",   context: "MyApp.Frontend"
  end
end
```

Multiple modifiers can be combined and are applied left to right — the last modifier to set a given option wins:

```elixir
~t"hello"eg   # if `g` sets domain: "default", the domain is "default" (not "errors")
~t"hello"ge   # if `e` sets domain: "errors", the domain is "errors"
```

Each modifier key must be a single lowercase letter (`a`–`z`) and accepts the options `:domain` and `:context`. Using an undefined modifier results in a compile-time error.

## Interpolation

Gettext [interpolation](https://hexdocs.pm/gettext/Gettext.html#module-interpolation) works similar to regular Elixir strings:

```elixir
~t"The #{fruit.name} is #{fruit.color.name}"

# is equivalent to
gettext(
  "The %{fruit_name} is %{fruit_color_name}",
  fruit_name: fruit.name, fruit_color_name: fruit.color.name
)
```

For simple variables and when accessing nested fields, the Gettext interpolation key is derived from the expression. This also works inside HEEx with assigns:

```heex
<div>{{~t"User: #{@user.name}"}}</div>
```

**Note:** The key is `assigns_user_name` because the expression is translated by HEEx to `assigns.user.name`.

For function calls, the key is derived from the function name:

```elixir
~t"Status: #{String.upcase(status)}"

# is equivalent to
gettext("Status: %{string_upcase}", string_upcase: String.upcase(status))
```

For expressions that don't map to a meaningful name, a generic `var` key is used:

```elixir
~t"Value: #{1 + 2}"

# is equivalent to
gettext("Value: %{var}", var: 1 + 2)
```

For more control over what key is used, the `::` syntax can be used:

```elixir
~t"Order status: #{status :: order_status(resp[field])}"

# is equivalent to
gettext("Order status: %{status}", status: order_status(resp[field]))
```

**Note:** Duplicate interpolation keys are automatically suffixed with a number to ensure uniqueness:

```elixir
~t"#{x :: "foo"} #{x :: "bar"}"

# is equivalent to
gettext("%{x1} %{x2}", x1: "foo", x2: "bar")
```

## Pluralization

Gettext pluralization (`ngettext`, ...) is currently **not** supported.

<!-- MDOC -->

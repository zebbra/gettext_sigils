# Gettext Sigils

An Elixir library that provides a `~t` sigil for using [`Gettext`](https://hexdocs.pm/gettext/Gettext.html) translations with:

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

Gettext [domain](https://hexdocs.pm/gettext/Gettext.html#module-domains) and [context](https://hexdocs.pm/gettext/Gettext.html#module-contexts) are provided as options when using the module and are used whenever using the `~t` sigil inside this module.

```elixir
defmodule MyApp.Errors.NotFound do
  use GettextSigils,
    backend: MyApp.Gettext,
    domain: "errors",
    context: inspect(__MODULE__)

  def description(path) do
    # uses domain and context from options
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

**Note:** Depending on the `domain` and `context` options, the `~t` sigil will use the corresponding Gettext macro (e.g. `gettext`, `dgettext`, `pgettext`, `dpgettext`)

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

For complex expressions, a generic key is generated from the position of the interpolation in the string:

```elixir
~t"Order status: #{order_status(resp[field])}"

# is equivalent to
gettext("Order status: %{var1}", %{var1: order_status(resp[field])})
```

For more control what key is used, the following syntax can be used:

```elixir
~t"Order status: #{status :: order_status(resp[field])}"

# is equivalent to
gettext("Order status: %{status}", %{status: order_status(resp[field])})
```

**Note:** The interpolation keys have to be unique! Duplicate keys will result in a compilation error:

```elixir
~t"Invalid: #{x :: "foo"} #{x :: "bar"}"
```

## Pluralization

Gettext pluralization (`ngettext`, ...) is currently **not** supported.

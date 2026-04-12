# Modifiers

Modifiers are single-letter suffixes on the `~t` sigil that tweak how a
translation is produced — override the Gettext domain or context, rewrite
the message, pluralize it, or transform the final translated string:

```elixir
~t"Not found"e               # override the Gettext domain
~t"#{count} error(s)"N       # pluralize
~t"hello"u                   # transform the result (e.g. upcase)
```

A sigil can carry multiple modifiers, which chain left-to-right:

```elixir
~t"Oops"em                   # override domain AND context
~t"#{count} error(s)"eN      # override domain AND pluralize
```

The letter-to-behavior mapping is defined by the using module's
`:modifiers` option.

> #### Reserved letters {: .info}
>
> Custom modifiers must use lowercase letters (`a`–`z`). Uppercase
> letters are reserved for library built-ins (currently only `N`).

## What modifiers can do

### Override domain and context

Modifiers can override the Gettext
[domain](https://hexdocs.pm/gettext/Gettext.html#module-domains) and
[context](https://hexdocs.pm/gettext/Gettext.html#module-contexts) on a
per-call basis. This is the most common use — the [keyword-list
form](#keyword-list-modifiers) is a built-in shorthand for it.

### Rewrite the message at compile time

A modifier can preprocess the `{msgid, bindings}` before it reaches
Gettext. This happens at compile time, so the rewritten msgid is what
ends up in your `.po` file. Use cases include rewriting custom inline
markup (e.g. turning `[b]...[/b]` into Phoenix component tags), adding
extra bindings, or stripping noise from the msgid.

### Pluralize

The built-in `N` modifier turns a message into a `dpngettext/6` plural
call, using the `count` binding to select the form at runtime:

```elixir
~t"#{count} error(s)"N
```

Translators then provide distinct singular and plural forms in the `.po`
file. See the [Pluralization guide](pluralization.html).

### Transform the translated string at runtime

A modifier can postprocess the final translated string. This happens at
runtime, after Gettext has looked up the translation and substituted
bindings:

```elixir
# a modifier that uppercases the result
~t"hello"u
# => String.upcase(dpgettext("default", nil, "hello", []))
# => "HELLO"
```

Because postprocessing runs at runtime, modifiers can wrap the string in
structs like `Phoenix.HTML.Safe`, apply markdown rendering, or anything
else you'd do to a string.

## Built-in modifiers

The only built-in modifier is `N` for pluralization. See the
[Pluralization guide](pluralization.html) for details and for how to
write a custom pluralization modifier with a different syntax.

## Keyword-list modifiers

The simplest way to define a custom modifier is a keyword list with
`:domain` and/or `:context` keys:

```elixir
defmodule MyApp.Frontend do
  use GettextSigils,
    backend: MyApp.Gettext,
    sigils: [
      domain: "frontend",
      modifiers: [
        e: [domain: "errors"],
        g: [domain: :default, context: nil],
        m: [context: inspect(__MODULE__)]
      ]
    ]

  def example do
    ~t"Welcome"           # domain: "frontend", context: nil
    ~t"Yes"g              # domain: :default,   context: nil
    ~t"Not found"e        # domain: "errors",   context: nil
    ~t"Hello"m            # domain: "frontend", context: "MyApp.Frontend"
    ~t"Oops"em            # domain: "errors",   context: "MyApp.Frontend"
  end
end
```

Each modifier key is a single lowercase letter (`a`–`z`). Options:

* `:domain` — binary or `:default` (the Gettext backend's configured
  default domain). Passing `nil` is deprecated and emits a compile-time
  warning; use `:default` instead.
* `:context` — binary or `nil` (no context)

Omitting a key leaves the current accumulator untouched. Modifiers chain
left-to-right, so `~t"Oops"em` applies `e` first (sets `domain: "errors"`)
then `m` (sets `context: "MyApp.Frontend"`).

For anything beyond domain and context — rewriting messages, transforming
the output, or validating options — use a
[module-based modifier](#module-based-modifiers).

## Module-based modifiers

For anything beyond domain and context — rewriting messages, transforming
the output, dynamic domain/context, opt validation — a modifier can point
at a module implementing the `GettextSigils.Modifier` behaviour:

```elixir
defmodule MyApp.UpcaseModifier do
  use GettextSigils.Modifier

  @impl true
  def postprocess(string, _opts), do: {:ok, String.upcase(string)}
end

defmodule MyApp.ShoutModifier do
  use GettextSigils.Modifier

  @impl true
  def postprocess(string, opts) do
    marks = String.duplicate("!", Keyword.get(opts, :intensity, 1))
    {:ok, string <> marks}
  end
end
```

Wire them up via `:modifiers`. An entry is either a bare module atom or
a `{module, opts}` tuple:

```elixir
use GettextSigils,
  backend: MyApp.Gettext,
  sigils: [
    domain: "frontend",
    modifiers: [
      u: MyApp.UpcaseModifier,
      s: {MyApp.ShoutModifier, intensity: 3}
    ]
  ]

~t"hello"u    # => "HELLO"
~t"hello"s    # => "hello!!!"
~t"hello"us   # => "HELLO!!!"   (upcase runs first, then shout)
```

### Example: Markdown postprocessing with MDEx

A modifier that renders translated strings as HTML via
[MDEx](https://hexdocs.pm/mdex/), passing options through to
`MDEx.to_html/2`:

```elixir
defmodule MyApp.MarkdownModifier do
  use GettextSigils.Modifier

  @impl true
  def postprocess(string, opts) do
    MDEx.to_html(string, opts)
  end
end
```

Wire it up with any MDEx options you need:

```elixir
use GettextSigils,
  backend: MyApp.Gettext,
  sigils: [
    modifiers: [
      m: {MyApp.MarkdownModifier, extension: [strikethrough: true]}
    ]
  ]

~t"**bold** and ~~struck~~"m
# => {:ok, "<p><strong>bold</strong> and <del>struck</del></p>\n"}
```

### Example: HTML-safe output with Phoenix.HTML

A modifier that wraps the translated string in
[`Phoenix.HTML.raw/1`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.html#raw/1)
so it renders as trusted HTML in HEEx templates:

```elixir
defmodule MyApp.RawModifier do
  use GettextSigils.Modifier

  @impl true
  def postprocess(string, _opts) do 
    {:ok, Phoenix.HTML.raw(string)}
  end
end
```

```elixir
use GettextSigils,
  backend: MyApp.Gettext,
  sigils: [
    modifiers: [
      r: MyApp.RawModifier
    ]
  ]

~t"<em>important</em>"r
# => {:safe, "<em>important</em>"}
```

See `GettextSigils.Modifier` for the full list of callbacks, their
timing (compile time vs runtime), and how to validate opts with `init/1`.

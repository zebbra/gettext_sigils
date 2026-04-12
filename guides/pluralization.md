# Pluralization

Gettext supports pluralization via `dpngettext/6`, which takes a distinct
msgid and msgid_plural and uses a runtime `count` to select between them.
GettextSigils exposes this through the pluralize callback on the
`GettextSigils.Modifier` behaviour. This guide covers the built-in `N`
modifier and shows how to write a custom one with a different syntax.

For general modifier usage, see the [Modifiers guide](modifiers.html).

## The built-in `N` modifier

Append `N` to any `~t` sigil that carries a `count` binding. GettextSigils
reuses the msgid as both `msgid` and `msgid_plural`, leaving translators
free to provide distinct forms later in the `.po` file:

```elixir
~t"#{count} error(s)"N
```

At compile time this emits roughly:

```elixir
dpngettext("default", nil, "%{count} error(s)", "%{count} error(s)", count, [])
```

Translators then provide the distinct forms in `.po`:

```pot
msgid "%{count} error(s)"
msgid_plural "%{count} error(s)"
msgstr[0] "One error"
msgstr[1] "%{count} errors"
```

The `count` binding can come from a variable or an explicit key:

```elixir
~t"#{count} items"N
~t"#{count = length(users)} user(s)"N
```

`count` must appear as a binding. Using `N` without one is a compile
error. `N` combines with other modifiers: `~t"#{count} error(s)"eN` uses
the `errors` domain.

## Writing a custom pluralization modifier

A custom pluralization modifier is a module that implements the
`pluralize/2` callback of the `GettextSigils.Modifier` behaviour. This
lets you change how a `~t` sigil is turned into a plural call — for
example, derive the `count` from a single interpolation, or split the
msgid into explicit singular and plural forms.

> #### Prefer the built-in `N` modifier {: .tip}
>
> The `pluralize/2` callback exists primarily to power the built-in `N`
> modifier. Most projects are well served by `N` plus
> translator-provided forms in the `.po` file — reach for a custom
> modifier only when you need behavior `N` cannot express.

As an example, here's an `n` modifier that splits the msgid on a
configurable separator (defaulting to `"|"`) into singular and plural
forms:

```elixir
defmodule MyApp.SplitPluralModifier do
  use GettextSigils.Modifier

  @schema NimbleOptions.new!(
    separator: [
      type: :string,
      default: "|",
      doc: "Separator between singular and plural forms in the msgid."
    ]
  )

  @impl true
  def init(opts), do: NimbleOptions.validate(opts, @schema)

  @impl true
  def pluralize({msgid, bindings}, opts) do
    case Keyword.pop(bindings, :count) do
      {nil, _} ->
        {:error, ~s|`n` modifier requires a "count" binding|}

      {count, remaining} ->
        separator = Keyword.fetch!(opts, :separator)

        case String.split(msgid, separator, parts: 2) do
          [singular, plural] ->
            {:ok, {singular, plural, count, remaining}}

          _ ->
            {:error, ~s|`n` modifier requires msgid in the form "singular#{separator}plural"|}
        end
    end
  end
end
```

`init/1` runs once at `use GettextSigils` time: it validates the opts
against the schema, applies the `"|"` default when `:separator` is
absent, and returns the validated opts — which are then passed as the
second argument to every `pluralize/2` call. Returning the
`NimbleOptions.ValidationError` struct directly works because the
`{:error, reason}` contract accepts either a string or an exception
(the library calls `Exception.message/1` internally).

Wire it up like any other modifier. Use the bare module atom for the
default separator, or a `{module, opts}` tuple to customize it:

```elixir
defmodule MyApp.Frontend do
  use GettextSigils,
    backend: MyApp.Gettext,
    sigils: [
      modifiers: [
        n: MyApp.SplitPluralModifier,
        p: {MyApp.SplitPluralModifier, separator: " :: "}
      ]
    ]

  def error_count(count), do: ~t"One error|#{count} errors"n
  def user_count(count), do: ~t"One user :: #{count} users"p
end
```

At compile time, `~t"One error|#{count} errors"n` emits:

```elixir
dpngettext("default", nil, "One error", "%{count} errors", count, [])
```

Gettext still translates the message at runtime — the modifier only
extracts the two forms from the sigil's msgid. The singular and plural
land in your `.po` file as distinct entries, just as if you had written
them using the `N` modifier:

```pot
msgid "One error"
msgid_plural "%{count} errors"
msgstr[0] "One error"
msgstr[1] "%{count} errors"
```

### `pluralize/2` return values

A `pluralize/2` callback returns one of two `{:ok, ...}` shapes:

* `{:ok, {msgid, bindings}}` — the message stays **singular**. The
  modifier may have rewritten the msgid or bindings, but no plural form
  is produced. The sigil continues down the modifier chain and
  ultimately emits `dpgettext/4`.
* `{:ok, {msgid, msgid_plural, count, bindings}}` — the message is
  **plural**. `count` is the runtime expression used to select the form.
  The sigil emits `dpngettext/6`.

`{:error, reason}` raises an `ArgumentError` at compile time.

### Only one pluralization per `~t` call

The sigil walks the modifier chain left-to-right and stops at the first
modifier that returns a plural tuple. Later modifiers in the chain still
run their other callbacks (`domain_context/3`, `preprocess/2`,
`postprocess/2`), but their `pluralize/2` is never invoked. In practice,
use at most one pluralization modifier per `~t` call.

See the [Modifiers guide](modifiers.html) and the
`GettextSigils.Modifier` behaviour for the full `pluralize/2` callback
signature and how it interacts with the other callbacks in a modifier
chain.

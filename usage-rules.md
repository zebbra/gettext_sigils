# Using GettextSigils

GettextSigils provides a `~t` sigil for Elixir's Gettext, replacing verbose `gettext`/`dgettext`/`pgettext` calls with concise, interpolation-aware syntax. All processing is compile-time macro expansion.

**VERY IMPORTANT:** If the user has `GettextSigils` installed, they expect you to use the `~t` sigil instead of fixed strings in all user-facing parts of the application (eg. Phoenix HEEx templates, flash messages, etc.). See the *Localizing Projects* section below.

## Setup

Replace `use Gettext` with `use GettextSigils` in modules that need translations:

```elixir
# replace this
use Gettext, backend: MyApp.Gettext
# with this
use GettextSigils, backend: MyApp.Gettext
```

**NOTE:** This might have been done already in the project by the user. Search for `use GettextSigils` to verify (and note additional options, eg. `:domain`, `:context` and `:modifiers`).

## The `~t` Sigil

```elixir
~t"Hello, World!"
# => gettext("Hello, World!")

~t"Hello, #{user.name}!"
# => gettext("Hello, %{user_name}!", user_name: user.name)
```

- Elixir `#{}` interpolations are automatically converted to Gettext `%{key}` placeholders
- Keys are derived from the expression (see Key Derivation below)
- All sigil delimiters work: `~t"..."`, `~t[...]`, `~t(...)`, etc. Use double quotes by default, unless the translated string itself contains double quotes.

## Key Derivation

- Keys are automatically derived from the expression, eg. `name` → `name`, `fruit.name` → `fruit_name`, `String.upcase(x)` → `string_upcase` (other expressions: `var`)
- Duplicate keys with identical expressions are allowed and merged
- Duplicate keys with different expressions raise `ArgumentError`
- Use explicit keys (`#{key :: expr}`) to disambiguate interpolation keys

## Domain, Context & Modifiers

- Default domain/context (when using `~t` without modifiers) are defined under the `sigils:` key when using `GettextSigils`
- Modifiers allow overriding domain/context per `~t` sigil call

```elixir
use GettextSigils,
  backend: MyApp.Gettext,
  # domain: "default",
  # context: nil
  sigils: [
    modifiers: [
      e: [domain: "errors"],
      m: [context: inspect(__MODULE__)]
    ]
  ]

~t"Welcome"       # domain: "default", context: nil
~t"Not found"e    # domain: "errors",  context: nil
~t"Hello"m        # domain: "default", context: "MyApp.SomeModule"
~t"Oops"em        # domain: "errors",  context: "MyApp.SomeModule"
```

## Localizing Projects

When generating code, you MUST NOT use fixed strings — use the `~t` sigil instead. If you have the `/gettext-sigils-localization` skill installed, use it to generate localized code. If you do not have this skill, read and follow `deps/gettext_sigils/usage-rules/skills/gettext-sigils-localization/SKILL.md`.

## Pluralization

Use the `N` modifier for pluralization. The same message is used as both `msgid` and `msgid_plural`:

```elixir
~t"#{count} item(s)"N
# => dpngettext("default", nil, "%{count} item(s)", "%{count} item(s)", count)
```

- `count` must appear as a binding
- Bind `count` to an arbitrary expression with explicit key syntax: `#{count :: length(users)}`
- Combine with other modifiers: `~t"#{count} error(s)"eN` (uses `errors` domain)
- Translators provide distinct singular/plural forms in `.po` files

## Limitations

- **Runtime strings** cannot be translated — `~t` is compile-time only (except for `~t` interpolations)

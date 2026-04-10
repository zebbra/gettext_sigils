# Interpolation

Gettext [interpolation](https://hexdocs.pm/gettext/Gettext.html#module-interpolation)
works similar to regular Elixir strings. The `~t` sigil parses the
interpolated expressions and turns them into Gettext `%{key}`
placeholders plus a keyword list of bindings — all at compile time:

```elixir
~t"The #{fruit.name} is #{color}"
# => gettext("The %{fruit_name} is %{color}", fruit_name: fruit.name, color: color)
```

## Automatic key derivation

The binding key for each `#{expr}` is derived from the shape of the
expression:

| Expression                           | Derived key     | Example                                            |
|--------------------------------------|-----------------|----------------------------------------------------|
| Simple variable `name`               | `name`          | `~t"Hi #{name}"` → `%{name}`                       |
| Module attribute `@count`            | `count`         | `~t"#{@count} items"` → `%{count}`                 |
| Assigns access `assigns.name`        | `name`          | `~t"Hi #{assigns.name}"` → `%{name}`               |
| Dot access `fruit.name`              | `fruit_name`    | `~t"#{fruit.name}"` → `%{fruit_name}`              |
| Deep dot access `a.b.c`              | `a_b_c`         | `~t"#{a.b.c}"` → `%{a_b_c}`                        |
| Module function `String.upcase(x)`   | `string_upcase` | `~t"#{String.upcase(x)}"` → `%{string_upcase}`     |
| Local function `status(x)`           | `status`        | `~t"#{status(x)}"` → `%{status}`                   |
| Operator / literal `1 + 2`           | `var`           | `~t"#{1 + 2}"` → `%{var}`                          |

All keys are lowercased and joined with underscores.

> #### HEEx assigns {: .info}
>
> The `assigns.name` form is for HEEx templates, which rewrite `@name` to
> `assigns.name` before the sigil sees them. Both forms derive the same key.

## Ambiguous keys

Duplicate keys are allowed if they refer to the same expression. The
binding appears only once in the emitted call:

```elixir
~t"#{name} is #{name}"
# => gettext("%{name} is %{name}", name: name)
```

When the same key would map to different expressions, the sigil raises
`ArgumentError` at compile time:

```elixir
~t"This is invalid: #{Foo.bar()} != #{foo.bar}"
# => ** (ArgumentError) ambiguous interpolation key "foo_bar" ...
```

Use explicit keys (below) to disambiguate.

## Explicit keys

Use the `key = expr` syntax to set the binding key explicitly. This is
useful when automatic derivation would collide, when the derived key
isn't meaningful (e.g. `var` for an operator), or when you want a
translator-friendly name:

```elixir
~t"Order status: #{status = order_status(resp[field])}"
# => gettext("Order status: %{status}", status: order_status(resp[field]))

~t"Valid: #{x = Foo.bar()} != #{y = foo.bar}"
# => gettext("Valid: %{x} != %{y}", x: Foo.bar(), y: foo.bar)
```

The left-hand side must be a plain variable; anything else raises at
compile time.

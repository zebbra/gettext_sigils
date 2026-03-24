defmodule GettextSigils.Interpolation do
  @moduledoc ~S"""
  Translates Elixir string interpolation into Gettext message format.

  Parses the AST of a `~t` sigil and produces a Gettext `msgid` string
  (with `%{key}` placeholders) and a keyword list of bindings.

  ## Key Derivation

  The interpolation key for each `#{}` expression is derived automatically
  from the expression's shape:

  | Expression                         | Derived key        | Example                                         |
  |------------------------------------|--------------------|--------------------------------------------------|
  | Simple variable `name`             | `name`             | `~t"Hi #{name}"` → `%{name}`                    |
  | Dot access `fruit.name`            | `fruit_name`       | `~t"#{fruit.name}"` → `%{fruit_name}`           |
  | Deep dot access `a.b.c`            | `a_b_c`            | `~t"#{a.b.c}"` → `%{a_b_c}`                     |
  | Module function `String.upcase(x)` | `string_upcase`    | `~t"#{String.upcase(x)}"` → `%{string_upcase}`  |
  | Local function `status(x)`         | `status`           | `~t"#{status(x)}"` → `%{status}`                |
  | Operator / literal `1 + 2`         | `var`              | `~t"#{1 + 2}"` → `%{var}`                       |
  | Explicit key `key :: expr`         | `key`              | `~t"#{status :: get()}"` → `%{status}`          |

  All keys are lowercased and joined with underscores.

  ## Ambiguous Keys

  When the same key appears more than once with the same value expression,
  the duplicates are merged (the key appears only once in the bindings):

      ~t"#{name} is #{name}"
      #=> msgid: "%{name} is %{name}", bindings: [name: name]

  When the same key appears with different value expressions, an
  `ArgumentError` is raised, prompting the user to provide distinct explicit
  keys:

      ~t"#{x :: foo} #{x :: bar}"
      #=> ** (ArgumentError) ambiguous interpolation key "x" with different values
  """

  @fallback_binding_key "var"

  def parse!(expr) do
    build_msgid_and_bindings!(expr)
  end

  # plain binary string — no interpolations
  defp build_msgid_and_bindings!(binary) when is_binary(binary), do: {binary, []}

  # List of segements from string interpolation:
  #
  # {:<<>>, meta, segments}
  #
  # each segment is either a literal binary or an interpolation node
  # shaped as `{:"::", _, [expr, {:binary, _, _}]}`.
  defp build_msgid_and_bindings!({:<<>>, _, segments} = expr) when is_list(segments) do
    {msgid_parts, bindings} =
      segments
      |> Enum.map(&segment_to_literal_or_binding/1)
      |> Enum.map_reduce([], fn
        {key, value}, acc ->
          {["%{", key, "}"], [{String.to_atom(key), value} | acc]}

        literal, acc when is_binary(literal) ->
          {literal, acc}
      end)

    msgid = IO.iodata_to_binary(msgid_parts)

    case deduplicate_bindings(bindings) do
      {unique_bindings, []} ->
        {msgid, unique_bindings}

      {_, ambiguous} ->
        raise ArgumentError,
              "Expression results in ambiguous Gettext interpolation keys:\n\n" <>
                "  expr: ~t#{Macro.to_string(expr)}\n" <>
                "  msgid: \"#{msgid}\" (ambiguous keys: #{Enum.join(ambiguous, ", ")})\n\n" <>
                "use the \"::\" operator to define a unique key-value binding, " <>
                "e.g. ~t\"\#{key :: <binding>}\"\n"
    end
  end

  defp deduplicate_bindings(bindings) do
    {bindings, duplicates, _seen} =
      Enum.reduce(bindings, {[], [], %{}}, fn {key, expr}, {keep, duplicates, seen} ->
        stripped_expr = strip_meta(expr)

        case Map.fetch(seen, key) do
          :error ->
            {
              [{key, expr} | keep],
              duplicates,
              Map.put(seen, key, stripped_expr)
            }

          {:ok, ^stripped_expr} ->
            {
              keep,
              duplicates,
              seen
            }

          {:ok, _} ->
            {
              keep,
              [key | duplicates],
              seen
            }
        end
      end)

    {bindings, duplicates}
  end

  defp strip_meta(ast) do
    Macro.prewalk(ast, fn
      {form, _meta, args} -> {form, [], args}
      other -> other
    end)
  end

  # literal binary segment -> no bindings
  defp segment_to_literal_or_binding(literal) when is_binary(literal) do
    literal
  end

  # string interpolation segment
  # #{x} -> {:x, x}
  defp segment_to_literal_or_binding({:"::", _, [expr, {:binary, _, _}]}) do
    {key, value_expr} =
      expr
      |> unwrap_kernel_to_string()
      |> binding_from_expr()

    {normalize_binding_key(key), value_expr}
  end

  # Extracts the interpolation key name and value expression from an
  # interpolated expression AST node.
  #
  # Handles two forms:
  #   - Explicit key:  `#{key :: expr}` → key derived from `key`, value is `expr`
  #   - Implicit key:  `#{expr}`        → key derived from `expr`, value is `expr`

  defp binding_from_expr({:"::", _, [{key, _, context}, value]}) when is_atom(key) and is_atom(context) do
    {key, value}
  end

  defp binding_from_expr(expr) do
    {binding_key_from_expr(expr), expr}
  end

  # String interpolation wraps each expression in `Kernel.to_string/1`.
  # This strips that wrapper to get the original expression.
  defp unwrap_kernel_to_string({{:., _, [Kernel, :to_string]}, _, [inner]}), do: inner
  defp unwrap_kernel_to_string(expr), do: expr

  ## Key derivation from AST expressions

  # Module attribute: `@count` → "count"
  defp binding_key_from_expr({:@, _, [{name, _, context}]}) when is_atom(name) and is_atom(context), do: name

  # Simple variable: `name` → "name"
  defp binding_key_from_expr({name, _, context}) when is_atom(name) and is_atom(context), do: name

  # Local function call or operator:
  #  - `order_status(x)` → "order_status"
  #  - `1 + 1` → "var"
  defp binding_key_from_expr({name, _, args}) when is_atom(name) and is_list(args) do
    if Macro.operator?(name, length(args)),
      do: @fallback_binding_key,
      else: name
  end

  # Assign access: `assigns.name` → "name" (HEEx transforms `@name` to `assigns.name`)
  defp binding_key_from_expr({{:., _, [{:assigns, _, _}, field]}, _, []}) when is_atom(field) do
    field
  end

  # Dot access: `fruit.name` → "fruit_name"
  defp binding_key_from_expr({{:., _, [receiver, field]}, _, []}) do
    [binding_key_from_expr(receiver), field]
  end

  # Module function call: `String.upcase("ok")` → "string_upcase"
  # module = [:String] func = :upcase
  defp binding_key_from_expr({{:., _, [{:__aliases__, _, modules}, func]}, _, _args}) do
    [modules, func]
  end

  # Fallback for expressions that don't map to a meaningful name.
  # Multiple occurrences will trigger an ArgumentError, prompting the
  # user to provide explicit keys via the `::` syntax.
  defp binding_key_from_expr(_expr), do: @fallback_binding_key

  # Normalize binding keys to lowercase strings
  #
  # [:a, ["b", :C], "D"] -> "a_b_c_d"

  defp normalize_binding_key(parts) when is_list(parts) do
    Enum.map_join(parts, "_", &normalize_binding_key/1)
  end

  defp normalize_binding_key(key) when is_atom(key) do
    key |> Atom.to_string() |> normalize_binding_key()
  end

  defp normalize_binding_key(key) when is_binary(key) do
    String.downcase(key)
  end
end

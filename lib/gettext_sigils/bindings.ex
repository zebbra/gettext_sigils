defmodule GettextSigils.Bindings do
  # Translates Elixir string interpolation AST into Gettext msgid format
  # and a keyword list of bindings.
  #
  # For example, the AST for `~t"Hello, #{user.name}"` becomes:
  #
  #   {"Hello, %{user_name}", [user_name: user.name]}
  #
  @moduledoc false

  alias GettextSigils.Error.DuplicateInterpolationKeys

  @fallback_binding_key "var"

  def parse(expr) do
    try do
      {:ok, parse!(expr)}
    rescue
      error -> {:error, error}
    end
  end

  def parse!(expr) do
    expr
    |> build_msgid_and_bindings()
    |> tap(&validate_duplicate_keys!(expr, &1))
  end

  defp validate_duplicate_keys!(expr, {msgid, bindings}) do
    duplicates =
      bindings
      |> Keyword.keys()
      |> find_duplicate_keys()

    if duplicates != [] do
      raise DuplicateInterpolationKeys, expr: expr, msgid: msgid, duplicates: duplicates
    end

    :ok
  end

  defp find_duplicate_keys(keys) do
    Enum.uniq(keys -- Enum.uniq(keys))
  end

  # plain binary string — no interpolations
  defp build_msgid_and_bindings(binary) when is_binary(binary), do: {binary, []}

  # List of segements from string interpolation:
  #
  # {:<<>>, meta, segments}
  #
  # each segment is either a literal binary or an interpolation node
  # shaped as `{:"::", _, [expr, {:binary, _, _}]}`.
  defp build_msgid_and_bindings({:<<>>, _, segments}) when is_list(segments) do
    parts =
      segments
      |> Enum.map(&segment_to_literal_or_binding/1)
      |> deduplicate_binding_keys()

    {msgid, bindings} =
      Enum.map_reduce(parts, [], fn
        {key, value}, acc ->
          {["%{", key, "}"], [{String.to_atom(key), value} | acc]}

        literal, acc when is_binary(literal) ->
          {literal, acc}
      end)

    {IO.iodata_to_binary(msgid), Enum.reverse(bindings)}
  end

  defp deduplicate_binding_keys(parts) do
    binding_keys =
      Enum.reduce(parts, [], fn
        {key, _}, acc -> [key | acc]
        _, acc -> acc
      end)

    freq = Enum.frequencies(binding_keys)

    {parts, _counts} =
      Enum.map_reduce(parts, %{}, fn
        {key, value}, counts ->
          count = Map.get(counts, key, 0) + 1
          new_key = if freq[key] > 1, do: "#{key}#{count}", else: key
          {{new_key, value}, Map.put(counts, key, count)}

        literal, counts ->
          {literal, counts}
      end)

    parts
  end

  # literal binary segment -> no bindings
  defp segment_to_literal_or_binding(literal) when is_binary(literal) do
    literal
  end

  # string interpolation segment
  # #{x} -> {"%{x}", [{:x, x}]}
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

  defp binding_from_expr({:"::", _, [{key, _, context}, value]})
       when is_atom(key) and is_atom(context) do
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

  # Simple variable: `name` → "name"
  defp binding_key_from_expr({name, _, context}) when is_atom(name) and is_atom(context),
    do: name

  # Local function call or operator:
  #  - `order_status(x)` → "order_status"
  #  - `1 + 1` → "var"
  defp binding_key_from_expr({name, _, args}) when is_atom(name) and is_list(args) do
    if Macro.operator?(name, length(args)),
      do: @fallback_binding_key,
      else: name
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
  # Multiple occurrences will trigger a DuplicateInterpolationKeys error,
  # prompting the user to provide explicit keys via the `::` syntax.
  defp binding_key_from_expr(_expr), do: @fallback_binding_key

  # Normalize binding keys to lowercase strings
  #
  # [:a, ["b", :C], "D] -> "a_b_c_d"

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

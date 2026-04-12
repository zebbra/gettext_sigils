defmodule GettextSigils.Modifiers do
  @moduledoc false

  alias GettextSigils.Modifier
  alias GettextSigils.Modifiers.PluralModifier

  @default_modifiers %{?N => {PluralModifier, []}}

  @type parsed :: {binary(), keyword()}
  @type plural :: {binary(), binary(), Macro.t(), keyword()}
  @type resolved :: [{module(), keyword()}]
  @type modifier_map :: %{optional(char()) => {module(), keyword()}}

  @doc """
  Maps each modifier letter in the sigil charlist to its `{module, opts}`
  pair, looking it up in the merge of `@default_modifiers` (built-in
  library modifiers like `N`) and the user-supplied `modifier_map`. The
  returned chain is in sigil order — every position in the charlist maps
  to one entry.

  User-supplied entries take precedence over the defaults on conflicting
  keys (currently impossible because built-ins use uppercase letters and
  user keys are validated to be lowercase).

  Raises `ArgumentError` at compile time when a modifier letter has no
  matching definition in either map.
  """
  @spec lookup_modifiers!(charlist(), modifier_map()) :: resolved()
  def lookup_modifiers!(modifiers, modifier_map) do
    merged = Map.merge(@default_modifiers, modifier_map)
    Enum.map(modifiers, &lookup_modifier!(&1, merged))
  end

  defp lookup_modifier!(char, modifier_map) do
    case Map.fetch(modifier_map, char) do
      {:ok, {_module, _opts} = entry} ->
        entry

      :error ->
        raise ArgumentError,
              "unknown sigil modifier #{inspect(List.to_atom([char]))}, " <>
                "defined modifiers: #{modifier_map |> Map.keys() |> Enum.map(&List.to_atom([&1])) |> inspect()}"
    end
  end

  @doc """
  Walks the resolved modifier chain left-to-right, calling each modifier's
  `domain_context/3` callback with the current `{domain, context}`
  accumulator. Returns the final `{domain, context}` tuple.

  A modifier that doesn't want to touch anything returns its third
  argument unchanged. `{:error, reason}` raises `ArgumentError`.
  """
  @spec resolve_domain_context!(
          resolved(),
          parsed(),
          {domain :: term(), context :: term()}
        ) :: {domain :: term(), context :: term()}
  def resolve_domain_context!(resolved, parsed, {_domain, _context} = defaults) do
    Enum.reduce_while(resolved, defaults, fn {module, mod_opts}, acc ->
      case module.domain_context(parsed, mod_opts, acc) do
        {:ok, {_new_domain, _new_context} = updated} -> {:cont, updated}
        {:error, reason} -> raise ArgumentError, format_error(reason)
      end
    end)
  end

  @doc """
  Walks the resolved modifier chain left-to-right, piping the parsed
  `{msgid, bindings}` tuple through each modifier's `preprocess/2`
  callback. Returns the final `{msgid, bindings}`. Raises `ArgumentError`
  if a callback returns `{:error, reason}`.
  """
  @spec preprocess!(resolved(), parsed()) :: parsed()
  def preprocess!(resolved, parsed) do
    Enum.reduce_while(resolved, parsed, fn {module, mod_opts}, acc ->
      case module.preprocess(acc, mod_opts) do
        {:ok, value} -> {:cont, value}
        {:error, reason} -> raise ArgumentError, format_error(reason)
      end
    end)
  end

  @doc """
  Walks the resolved modifier chain looking for the first modifier whose
  `pluralize/2` callback returns a plural tuple
  `{msgid, msgid_plural, count, bindings}`.

  Returns either:

    * the original `{msgid, bindings}` (no modifier in the chain wanted to
      pluralize), or
    * the plural tuple from the first modifier that did.

  Raises `ArgumentError` at compile time when a modifier returns
  `{:error, reason}` from `pluralize/2`.
  """
  @spec pluralize!(resolved(), parsed()) :: parsed() | plural()
  def pluralize!(resolved, parsed) do
    Enum.reduce_while(resolved, parsed, fn {module, mod_opts}, acc ->
      case module.pluralize(acc, mod_opts) do
        {:ok, {_msgid, _bindings} = singular} -> {:cont, singular}
        {:ok, {_msgid, _msgid_plural, _count, _bindings} = plural} -> {:halt, plural}
        {:error, reason} -> raise ArgumentError, format_error(reason)
      end
    end)
  end

  @doc """
  Walks the resolved modifier chain left-to-right at runtime, piping the
  translated `string` through each modifier's `postprocess/2` callback.
  Returns the final transformed value (which may be any term, e.g. a
  `Phoenix.HTML.Safe` struct). Raises `ArgumentError` at runtime if a
  callback returns `{:error, reason}`.

  Called from the AST emitted by `GettextSigils.Sigil.sigil_t/2`.
  """
  @spec postprocess!(resolved(), term()) :: term()
  def postprocess!(resolved, string) do
    Enum.reduce_while(resolved, string, fn {module, mod_opts}, acc ->
      case module.postprocess(acc, mod_opts) do
        {:ok, value} -> {:cont, value}
        {:error, reason} -> raise ArgumentError, format_error(reason)
      end
    end)
  end

  @doc false
  @spec format_error(Modifier.reason()) :: String.t()
  def format_error(reason) when is_binary(reason), do: reason
  def format_error(%{__exception__: true} = exception), do: Exception.message(exception)
end

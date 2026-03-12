defmodule GettextSigils.Modifiers do
  @moduledoc false

  @doc """
  Resolves the given charlist of sigil modifiers to a Gettext domain and context,
  returned as `{domain, context}`.
  """

  @spec resolve!(modifiers :: charlist(), opts :: Keyword.t()) :: {binary() | :default, atom() | nil}
  def resolve!(modifiers, opts) do
    domain = Keyword.get(opts, :domain, :default)
    context = Keyword.get(opts, :context, nil)
    modifier_defs = Keyword.get(opts, :modifiers, [])

    do_resolve(modifiers, modifier_defs, {domain, context})
  end

  defp do_resolve([], _defs, {domain, context}), do: {domain, context}

  defp do_resolve([mod | remaining_mods], modifier_defs, {domain, context}) do
    mod_key = List.to_atom([mod])

    case Keyword.fetch(modifier_defs, mod_key) do
      {:ok, overrides} ->
        new_domain = Keyword.get(overrides, :domain, domain) || :default
        new_context = Keyword.get(overrides, :context, context)

        do_resolve(
          remaining_mods,
          modifier_defs,
          {new_domain, new_context}
        )

      :error ->
        raise ArgumentError,
              "unknown sigil modifier #{inspect(mod_key)}, " <>
                "defined modifiers: #{inspect(Keyword.keys(modifier_defs))}"
    end
  end
end

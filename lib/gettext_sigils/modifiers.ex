defmodule GettextSigils.Modifiers do
  @moduledoc false

  @plural_modifier ?N

  @doc """
  Resolves the given charlist of sigil modifiers to a Gettext domain, context,
  and pluralization flag, returned as `{domain, context, plural?}`.

  The built-in `N` modifier enables pluralization. All other modifiers (lowercase
  `a`–`z`) are resolved against user-defined modifier definitions.
  """

  @spec resolve!(modifiers :: charlist(), opts :: Keyword.t()) ::
          {binary() | :default, atom() | nil, boolean()}
  def resolve!(modifiers, opts) do
    {plural?, modifiers} = extract_plural(modifiers)

    domain = Keyword.get(opts, :domain, :default)
    context = Keyword.get(opts, :context, nil)
    modifier_defs = Keyword.get(opts, :modifiers, [])

    {domain, context} = do_resolve(modifiers, modifier_defs, {domain, context})
    {domain, context, plural?}
  end

  defp extract_plural(modifiers) do
    if @plural_modifier in modifiers do
      {true, List.delete(modifiers, @plural_modifier)}
    else
      {false, modifiers}
    end
  end

  defp do_resolve([], _defs, acc), do: acc

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

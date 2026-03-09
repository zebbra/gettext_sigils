defmodule GettextSigils do
  @moduledoc false

  defmacro __using__(opts) do
    {sigils_opts, gettext_opts} = Keyword.pop(opts, :sigils, [])
    validate_modifiers!(Keyword.get(sigils_opts, :modifiers, []))

    quote do
      use Gettext, unquote(gettext_opts)

      import GettextSigils.Sigil

      @__gettext_sigils__ unquote(sigils_opts)
    end
  end

  defp validate_modifiers!(modifiers) do
    for {key, opts} <- modifiers do
      key_str = Atom.to_string(key)

      unless String.length(key_str) == 1 and key_str =~ ~r/^[a-z]$/ do
        raise ArgumentError,
          "modifier keys must be lowercase letters (a-z), got: #{inspect(key)}"
      end

      if Keyword.has_key?(opts, :domain) and Keyword.get(opts, :domain) == nil do
        raise ArgumentError,
          "modifier #{inspect(key)}: domain cannot be nil, Gettext always requires a domain"
      end
    end
  end
end

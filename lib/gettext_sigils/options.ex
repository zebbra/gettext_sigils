defmodule GettextSigils.Options do
  @moduledoc false

  @valid_modifier_keys [:domain, :context]

  def validate!(opts) do
    validate_modifiers!(Keyword.get(opts, :modifiers, []))
  end

  defp validate_modifiers!(modifiers) do
    for {key, opts} <- modifiers do
      unless Atom.to_string(key) =~ ~r/^[a-z]$/ do
        raise ArgumentError,
          "modifier keys must be lowercase letters (a-z), got: #{inspect(key)}"
      end

      unless Keyword.keyword?(opts) do
        raise ArgumentError,
          "modifier #{inspect(key)}: options must be a keyword list, got: #{inspect(opts)}"
      end

      invalid_keys = Keyword.keys(opts) -- @valid_modifier_keys

      if invalid_keys != [] do
        raise ArgumentError,
          "modifier #{inspect(key)}: unknown options #{inspect(invalid_keys)}, " <>
            "expected: #{inspect(@valid_modifier_keys)}"
      end

      if Keyword.has_key?(opts, :domain) and Keyword.get(opts, :domain) == nil do
        raise ArgumentError,
          "modifier #{inspect(key)}: domain cannot be nil, Gettext always requires a domain"
      end
    end
  end
end

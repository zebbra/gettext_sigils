defmodule GettextSigils.Options do
  @moduledoc false

  @valid_keys [:domain, :context, :modifiers, :pluralization]
  @valid_modifier_keys [:domain, :context]
  @valid_pluralization_keys [:separator]

  def validate!(opts) do
    validate_unknown_keys!(opts)
    validate_domain!(opts)
    validate_context!(opts)
    validate_modifiers!(Keyword.get(opts, :modifiers, []))
    validate_pluralization!(Keyword.get(opts, :pluralization, []))
  end

  defp validate_unknown_keys!(opts) do
    invalid_keys = Keyword.keys(opts) -- @valid_keys

    if invalid_keys != [] do
      raise ArgumentError,
            "unknown options #{inspect(invalid_keys)}, expected: #{inspect(@valid_keys)}"
    end
  end

  defp validate_domain!(opts) do
    case Keyword.fetch(opts, :domain) do
      {:ok, domain} when is_binary(domain) -> :ok
      {:ok, other} -> raise ArgumentError, "domain must be a string, got: #{inspect(other)}"
      :error -> :ok
    end
  end

  defp validate_context!(opts) do
    case Keyword.fetch(opts, :context) do
      {:ok, context} when is_binary(context) or is_nil(context) -> :ok
      {:ok, other} -> raise ArgumentError, "context must be a string or nil, got: #{inspect(other)}"
      :error -> :ok
    end
  end

  defp validate_modifiers!(modifiers) when not is_list(modifiers) do
    raise ArgumentError, "modifiers must be a keyword list, got: #{inspect(modifiers)}"
  end

  defp validate_modifiers!(modifiers) do
    for {key, opts} <- modifiers do
      if !(Atom.to_string(key) =~ ~r/^[a-z]$/) do
        raise ArgumentError,
              "modifier keys must be lowercase letters (a-z), got: #{inspect(key)}"
      end

      if !Keyword.keyword?(opts) do
        raise ArgumentError,
              "modifier #{inspect(key)}: options must be a keyword list, got: #{inspect(opts)}"
      end

      invalid_keys = Keyword.keys(opts) -- @valid_modifier_keys

      if invalid_keys != [] do
        raise ArgumentError,
              "modifier #{inspect(key)}: unknown options #{inspect(invalid_keys)}, " <>
                "expected: #{inspect(@valid_modifier_keys)}"
      end

      with {:ok, nil} <- Keyword.fetch(opts, :domain) do
        raise ArgumentError,
              "modifier #{inspect(key)}: domain cannot be nil, Gettext always requires a domain"
      end
    end
  end

  defp validate_pluralization!(opts) when not is_list(opts) do
    raise ArgumentError, "pluralization must be a keyword list, got: #{inspect(opts)}"
  end

  defp validate_pluralization!(opts) do
    if !Keyword.keyword?(opts) do
      raise ArgumentError, "pluralization must be a keyword list, got: #{inspect(opts)}"
    end

    unknown_keys = Keyword.keys(opts) -- @valid_pluralization_keys

    if unknown_keys != [] do
      raise ArgumentError,
            "unknown pluralization options #{inspect(unknown_keys)}, expected: #{inspect(@valid_pluralization_keys)}"
    end

    case Keyword.fetch(opts, :separator) do
      {:ok, sep} when is_binary(sep) and byte_size(sep) > 0 -> :ok
      {:ok, other} -> raise ArgumentError, "separator must be a non-empty string, got: #{inspect(other)}"
      :error -> :ok
    end
  end

  def pluralization_separator(opts) do
    opts
    |> Keyword.get(:pluralization, [])
    |> Keyword.get_lazy(:separator, &GettextSigils.Pluralization.default_separator/0)
  end
end

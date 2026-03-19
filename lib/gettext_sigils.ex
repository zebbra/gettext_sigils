defmodule GettextSigils do
  @moduledoc """
  Imports the `~t` sigil into the module that is using this module, eg.

  ```elixir
  use GettextSigils,
    backend: MyApp.Gettext,
    sigils: [
      # ...
    ]
  ```

  ## Options

  - `:sigils` - a keyword list of options for the sigil. See `GettextSigils.Options` for the available options.
  - All other options are passed to `use Gettext` (eg. `:backend`).

  """

  defmacro __using__(opts) do
    {sigils_opts, gettext_opts} = Keyword.pop(opts, :sigils, [])

    quote do
      use Gettext, unquote(gettext_opts)

      import GettextSigils.Sigil

      @__gettext_sigils__ GettextSigils.Options.validate!(unquote(sigils_opts))
    end
  end
end

defmodule GettextSigils.Modifiers.NoopModifier do
  @moduledoc ~S"""
  Built-in modifier behind the `X` sigil modifier: marks the message for
  extraction and returns the msgid unchanged, like `Gettext.Macros.gettext_noop/1`.

  `preprocess/2` tags the input as `{:noop, input}`. The other modifiers'
  `preprocess/2` and `pluralize/2` callbacks still see the untagged input, so
  they shape the msgid wherever they sit in the chain. For a tagged message the
  sigil emits `dpgettext_noop/3` (or `dpngettext_noop/4` together with `N`,
  which returns `{msgid, msgid_plural}`) instead of a lookup, so domain and
  context modifiers still decide where the message is extracted to. Interpolated
  expressions are never evaluated; only their `%{key}` placeholders end up in
  the msgid, and no `postprocess/2` callback runs. Translate the result later
  with `Gettext.dpgettext/5` and the same domain and context.

      ~t"Archived"X
      # => dpgettext_noop(:default, nil, "Archived")
      # => "Archived"
  """

  use GettextSigils.Modifier

  @impl true
  def preprocess(input, _opts), do: {:ok, {:noop, input}}
end

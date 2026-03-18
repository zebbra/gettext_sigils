defmodule GettextSigilsTest.Gettext do
  @moduledoc """
  Real Gettext backend for testing
  """
  use Gettext.Backend,
    otp_app: :gettext_sigils,
    priv: "test/support/gettext"
end

defmodule GettextSigilsTest.GettextTest do
  @moduledoc false
  use GettextSigils,
    backend: GettextSigilsTest.Gettext,
    sigils: [
      domain: "example",
      modifiers: [
        e: [domain: "errors"],
        m: [context: inspect(__MODULE__)]
      ]
    ]

  def without_modifiers, do: ~t"without modifiers"
  def with_modifiers, do: ~t"with modifiers"em
  def with_interpolation(i), do: ~t"with #{i}"
  def with_pluralization(count), do: ~t"One||High #{count}!"
end

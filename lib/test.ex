defmodule Test.Gettext do
  @moduledoc false
  use Gettext.Backend, otp_app: :gettext_sigils
end

defmodule Test do
  @moduledoc false
  use GettextSigils, backend: Test.Gettext

  def hello(foo) do
    ~t"Hello #{foo} #{foo}"
  end
end

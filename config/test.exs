import Config

config :gettext_sigils, GettextSigilsTest.Gettext,
  default_locale: "en",
  locales: ~w(en de fr)

# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule NiceRF_SV6xx.MixProject do
  use Mix.Project

  def project do
    [
      app: :nicerf_sv6xx,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "NiceRF_SV6xx",
      source_url: "https://github.com/easink/nicerf_sv6xx"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_uart, "~> 1.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

    defp description() do
    "Library for NiceRF SV6xx devices."
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "nicerf_sv6xx",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/easink/nicerf_sv6xx"}
    ]
  end
end

import Config

config :ex_odata4, ExOdata4.Repo,
  database: "priv/repo/ex_odata4_dev.db",
  pool_size: 5

config :ex_odata4,
  ecto_repos: []

if config_env() == :test do
  import_config "test.exs"
end

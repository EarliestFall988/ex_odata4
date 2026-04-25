# test/support/repo.ex
defmodule ExOdata4.Test.Repo do
  use Ecto.Repo,
    otp_app: :ex_odata4,
    adapter: Ecto.Adapters.SQLite3
end

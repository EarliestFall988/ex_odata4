# test/support/schema.ex
defmodule ExOdata4.Test.Trade do
  use Ecto.Schema

  schema "trades" do
    field :name, :string
    field :amount, :float
    field :status, :string
    field :active, :boolean
  end
end

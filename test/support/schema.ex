# test/support/schema.ex
defmodule ExOdata4.Test.Trade do
  use Ecto.Schema

  schema "trades" do
    field :name, :string
    field :amount, :float
    field :status, :string
    field :active, :boolean
    field :date, :date
  end
end

defmodule ExOdata4.Test.AllTypes do
  use Ecto.Schema

  schema "all_types" do
    field :string_field,    :string
    field :integer_field,   :integer
    field :float_field,     :float
    field :decimal_field,   :decimal
    field :boolean_field,   :boolean
    field :date_field,      :date
    field :datetime_field,  :utc_datetime
    field :guid_field,      :binary_id
  end
end

defmodule ExOdata4.Repo.Migrations.Batman do
  use Ecto.Migration

  def change do

      create table(:trades) do
        add :name, :string
        add :amount, :float
        add :status, :string
        add :active, :boolean
      end

  end
end

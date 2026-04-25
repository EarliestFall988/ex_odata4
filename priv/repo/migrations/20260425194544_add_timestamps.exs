defmodule ExOdata4.Repo.Migrations.AddTimestamps do
  use Ecto.Migration

  def change do
    alter table(:trades) do
      timestamps()
    end
  end
end

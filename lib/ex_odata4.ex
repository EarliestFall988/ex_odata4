defmodule ExOdata4 do
  @moduledoc """
  An OData v4 query parser and Ecto query builder.

  Parses OData query strings or full URIs and returns `Ecto.Query` structs
  ready to execute against your own repo.

  ## Configuration

  Map OData entity names to your Ecto schema modules in `config/config.exs`:

      config :ex_odata4, schemas: %{
        "Orders" => MyApp.Orders,
        "Products" => MyApp.Products
      }

  ## Usage

  Parse a full OData URI:

      ExOdata4.parse_uri("/Orders?\\$filter=Amount gt 1000&\\$top=25")
      |> MyApp.Repo.all()

  Or parse a query string directly when you already know the entity name:

      ExOdata4.get("Orders", "\\$filter=Status eq 'active'&\\$top=10")
      |> MyApp.Repo.all()

  Both functions return an `%Ecto.Query{}` — execute it with whichever repo
  and database adapter your application uses.
  """
  def parse_uri(uri) do
    [path | query] = String.split(uri, "?")

    schema_name =
      path
      |> String.trim("/")
      |> String.split("/")
      |> List.last()

    query_string = Enum.join(query, "?")
    get(schema_name, query_string)

  end

  def get(schema_name, query_string) do
    schema = schema_for!(schema_name)

    case ExOdata4.Parser.parse_query(query_string) do
      {:ok, ast} ->
        ExOdata4.Ecto.Builder.build(schema, ast)

      {:error, reason} ->
        raise "Failed to parse OData query: #{reason}"
    end
  end

  defp schema_for!(name) do
    schemas = Application.get_env(:ex_odata4, :schemas, %{})

    case Map.get(schemas, name) do
      nil ->
        raise """
        No schema configured for "#{name}".

        Add it to your config.exs:

            config :ex_odata4, schemas: %{
              "#{name}" => MyApp.#{name}
            }

        See: https://hexdocs.pm/ex_odata4/configuration.html
        """

      module ->
        module
    end
  end
end

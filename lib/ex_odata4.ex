defmodule ExOdata4 do
  @moduledoc """
  Documentation for `ExOdata4`.
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

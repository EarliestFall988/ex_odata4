defmodule ExOdata4.Metadata do
  @moduledoc """
  Generates OData $metadata XML documents from Ecto schemas.
  """

  @edm_types %{
    :id            => "Edm.Int32",
    :integer       => "Edm.Int32",
    :float         => "Edm.Double",
    :decimal       => "Edm.Decimal",
    :string        => "Edm.String",
    :boolean       => "Edm.Boolean",
    :date          => "Edm.Date",
    :utc_datetime  => "Edm.DateTimeOffset",
    :naive_datetime => "Edm.DateTimeOffset",
    :binary_id     => "Edm.Guid"
  }

  @doc """
  Generates an OData $metadata XML document for the given Ecto schema.

  Options:
    - `:namespace` — the OData namespace (default: `"Default"`)
  """
  def generate(schema, opts \\ []) do
    namespace    = Keyword.get(opts, :namespace, "Default")
    entity_type  = entity_type_name(schema)
    entity_set   = entity_set_name(schema)
    primary_keys = schema.__schema__(:primary_key)
    fields       = schema.__schema__(:fields)

    properties = Enum.map_join(fields, "\n", fn field ->
      name     = to_odata_name(field)
      edm_type = edm_type(schema, field)
      ~s(        <Property Name="#{name}" Type="#{edm_type}" Nullable="true"/>)
    end)

    key_refs = Enum.map_join(primary_keys, "\n", fn field ->
      ~s(          <PropertyRef Name="#{to_odata_name(field)}"/>)
    end)

    """
    <?xml version="1.0" encoding="utf-8"?>
    <edmx:Edmx Version="4.0" xmlns:edmx="http://docs.oasis-open.org/odata/ns/edmx">
      <edmx:DataServices>
        <Schema Namespace="#{namespace}" xmlns="http://docs.oasis-open.org/odata/ns/edm">
          <EntityType Name="#{entity_type}">
            <Key>
    #{key_refs}
            </Key>
    #{properties}
          </EntityType>
          <EntityContainer Name="DefaultContainer">
            <EntitySet Name="#{entity_set}" EntityType="#{namespace}.#{entity_type}"/>
          </EntityContainer>
        </Schema>
      </edmx:DataServices>
    </edmx:Edmx>
    """
  end

  defp entity_type_name(schema) do
    schema
    |> Module.split()
    |> List.last()
  end

  defp entity_set_name(schema) do
    schema.__schema__(:source)
    |> String.split("_")
    |> Enum.map_join(&String.capitalize/1)
  end

  defp to_odata_name(field) do
    field
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map_join(&String.capitalize/1)
  end

  defp edm_type(schema, field) do
    ecto_type = schema.__schema__(:type, field)
    Map.get(@edm_types, ecto_type, "Edm.String")
  end
end

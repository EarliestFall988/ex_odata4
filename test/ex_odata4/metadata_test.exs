defmodule ExOdata4.MetadataTest do
  use ExUnit.Case

  alias ExOdata4.Metadata
  alias ExOdata4.Test.{Trade, AllTypes}

  describe "generate/2 - document structure" do
    test "returns a valid XML string" do
      xml = Metadata.generate(Trade)
      assert is_binary(xml)
      assert xml =~ ~s(<?xml version="1.0" encoding="utf-8"?>)
    end

    test "contains the OData edmx envelope" do
      xml = Metadata.generate(Trade)
      assert xml =~ ~s(edmx:Edmx)
      assert xml =~ ~s(Version="4.0")
      assert xml =~ ~s(edmx:DataServices)
    end

    test "contains a Schema element" do
      xml = Metadata.generate(Trade)
      assert xml =~ ~s(<Schema)
    end
  end

  describe "generate/2 - entity naming" do
    test "EntityType name is derived from the module name" do
      xml = Metadata.generate(Trade)
      assert xml =~ ~s(EntityType Name="Trade")
    end

    test "EntitySet name is derived from the schema source table" do
      xml = Metadata.generate(Trade)
      assert xml =~ ~s(EntitySet Name="Trades")
    end

    test "EntitySet EntityType references the correct type" do
      xml = Metadata.generate(Trade)
      assert xml =~ ~s(EntityType="Default.Trade")
    end

    test "namespace option overrides the default" do
      xml = Metadata.generate(Trade, namespace: "MyApp")
      assert xml =~ ~s(Namespace="MyApp")
      assert xml =~ ~s(EntityType="MyApp.Trade")
    end

    test "default namespace is Default" do
      xml = Metadata.generate(Trade)
      assert xml =~ ~s(Namespace="Default")
    end
  end

  describe "generate/2 - primary key" do
    test "Key element references the primary key field" do
      xml = Metadata.generate(Trade)
      assert xml =~ ~s(<Key>)
      assert xml =~ ~s(PropertyRef Name="Id")
    end
  end

  describe "generate/2 - properties" do
    test "each schema field appears as a Property" do
      xml = Metadata.generate(Trade)
      assert xml =~ ~s(Property Name="Name")
      assert xml =~ ~s(Property Name="Amount")
      assert xml =~ ~s(Property Name="Status")
      assert xml =~ ~s(Property Name="Active")
      assert xml =~ ~s(Property Name="Date")
    end

    test "primary key field is also included as a property" do
      xml = Metadata.generate(Trade)
      assert xml =~ ~s(Property Name="Id")
    end
  end

  describe "generate_service/2 - combined document" do
    test "returns a valid XML string" do
      xml = Metadata.generate_service(%{"Trades" => Trade, "AllTypes" => AllTypes})
      assert is_binary(xml)
      assert xml =~ ~s(<?xml version="1.0" encoding="utf-8"?>)
    end

    test "contains the OData edmx envelope" do
      xml = Metadata.generate_service(%{"Trades" => Trade})
      assert xml =~ ~s(edmx:Edmx)
      assert xml =~ ~s(Version="4.0")
    end

    test "includes an EntityType for each schema" do
      xml = Metadata.generate_service(%{"Trades" => Trade, "AllTypes" => AllTypes})
      assert xml =~ ~s(EntityType Name="Trade")
      assert xml =~ ~s(EntityType Name="AllTypes")
    end

    test "includes an EntitySet for each schema" do
      xml = Metadata.generate_service(%{"Trades" => Trade, "AllTypes" => AllTypes})
      assert xml =~ ~s(EntitySet Name="Trades")
      assert xml =~ ~s(EntitySet Name="AllTypes")
    end

    test "all entity sets are in a single EntityContainer" do
      xml = Metadata.generate_service(%{"Trades" => Trade, "AllTypes" => AllTypes})
      assert [_] = Regex.scan(~r/<EntityContainer/, xml)
    end

    test "all entity types are in a single Schema" do
      xml = Metadata.generate_service(%{"Trades" => Trade, "AllTypes" => AllTypes})
      assert [_] = Regex.scan(~r/<Schema/, xml)
    end

    test "namespace option is applied to all entity types" do
      xml = Metadata.generate_service(%{"Trades" => Trade}, namespace: "MyApp")
      assert xml =~ ~s(Namespace="MyApp")
      assert xml =~ ~s(EntityType="MyApp.Trade")
    end

    test "properties of each schema are included" do
      xml = Metadata.generate_service(%{"Trades" => Trade, "AllTypes" => AllTypes})
      assert xml =~ ~s(Property Name="Amount")
      assert xml =~ ~s(Property Name="StringField")
    end
  end

  describe "generate/2 - EDM type mapping" do
    test "string maps to Edm.String" do
      xml = Metadata.generate(AllTypes)
      assert xml =~ ~s(Name="StringField" Type="Edm.String")
    end

    test "integer maps to Edm.Int32" do
      xml = Metadata.generate(AllTypes)
      assert xml =~ ~s(Name="IntegerField" Type="Edm.Int32")
    end

    test "float maps to Edm.Double" do
      xml = Metadata.generate(AllTypes)
      assert xml =~ ~s(Name="FloatField" Type="Edm.Double")
    end

    test "decimal maps to Edm.Decimal" do
      xml = Metadata.generate(AllTypes)
      assert xml =~ ~s(Name="DecimalField" Type="Edm.Decimal")
    end

    test "boolean maps to Edm.Boolean" do
      xml = Metadata.generate(AllTypes)
      assert xml =~ ~s(Name="BooleanField" Type="Edm.Boolean")
    end

    test "date maps to Edm.Date" do
      xml = Metadata.generate(AllTypes)
      assert xml =~ ~s(Name="DateField" Type="Edm.Date")
    end

    test "utc_datetime maps to Edm.DateTimeOffset" do
      xml = Metadata.generate(AllTypes)
      assert xml =~ ~s(Name="DatetimeField" Type="Edm.DateTimeOffset")
    end

    test "binary_id maps to Edm.Guid" do
      xml = Metadata.generate(AllTypes)
      assert xml =~ ~s(Name="GuidField" Type="Edm.Guid")
    end
  end
end

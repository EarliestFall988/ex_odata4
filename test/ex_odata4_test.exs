defmodule ExOdata4Test do
  use ExUnit.Case

  test "parse_uri extracts schema name and query string" do
    query = ExOdata4.parse_uri("/Trades?$filter=Amount gt 100")
    assert %Ecto.Query{} = query
  end

  test "get returns an Ecto query" do
    query = ExOdata4.get("Trades", "$filter=Amount gt 100")
    assert %Ecto.Query{} = query
  end

  test "get raises a clear error for unknown schema" do
    assert_raise RuntimeError, ~r/No schema configured for "Unknown"/, fn ->
      ExOdata4.get("Unknown", "$filter=Amount gt 100")
    end
  end
end

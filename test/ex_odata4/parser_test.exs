defmodule ExOdata4.ParserTest do
  use ExUnit.Case
  alias ExOdata4.Parser
  doctest ExOdata4.Parser

  defp assert_parses(input) do
    assert {:ok, _result, "", _, _, _} = Parser.parse_literal(input),
           "failed to parse: #{input}"
  end

  defp assert_parses_filter(input) do
    assert {:ok, _result, "", _, _, _} = Parser.parse_filter(input),
           "failed to parse filter: #{input}"
  end

  defp assert_parses_top(input) do
    assert {:ok, _result, "", _, _, _} = Parser.parse_top(input),
           "failed to parse top: #{input}"
  end

  defp assert_parses_skip(input) do
    assert {:ok, _result, "", _, _, _} = Parser.parse_skip(input),
           "failed to parse skip: #{input}"
  end

  defp assert_parses_orderby(input) do
    assert {:ok, _result, "", _, _, _} = Parser.parse_orderby(input),
           "failed to parse orderby: #{input}"
  end

  test "orderby parameter" do
    assert_parses_orderby("$orderby=Name")
  end

  test "top parameter" do
    assert_parses_top("$top=10")
  end

  test "skip parameter" do
    assert_parses_skip("$skip=5")
  end

  test "null literal" do
    assert_parses("null")
  end

  test "boolean literals" do
    assert_parses("true")
    assert_parses("false")
  end

  test "string literals" do
    assert_parses("'John'")
    # escaped quote
    assert_parses("'John''s'")
    # empty string
    assert_parses("''")
  end

  test "integer literals" do
    assert_parses("1000")
    assert_parses("-1000")
    assert_parses("1000L")
  end

  test "decimal literals" do
    assert_parses("3.14")
    assert_parses("-3.14")
  end

  test "date literals" do
    assert_parses("2024-01-01")
  end

  test "datetime offset literals" do
    assert_parses("2024-01-01T00:00:00Z")
    assert_parses("2024-01-01T13:45:30+05:00")
    assert_parses("2024-01-01T13:45:30.123Z")
  end

  test "guid literals" do
    assert_parses("12345678-1234-1234-1234-123456789012")
  end

  test "simple comparison expressions" do
    assert_parses_filter("Name eq 'John'")
    assert_parses_filter("Amount gt 1000")
    assert_parses_filter("Active eq true")
    assert_parses_filter("Date eq 2024-01-01")
    assert_parses_filter("Amount ge 3.14")
    assert_parses_filter("Amount ne -1000")
    assert_parses_filter("Timestamp eq 2024-01-01T00:00:00Z")
    assert_parses_filter("Id eq 12345678-1234-1234-1234-123456789012")
  end

  test "logical expressions" do
    assert_parses_filter("Amount gt 1000 and Status eq 'Settled'")
    assert_parses_filter("Amount gt 1000 or Amount lt 0")
    assert_parses_filter("Amount gt 1000 and Status eq 'Settled' and Risk eq 'High'")
  end

  test "parenthesized expressions" do
    assert_parses_filter("(Amount gt 1000 and Status eq 'Settled') or Risk eq 'High'")
    assert_parses_filter("(Amount gt 1000) and (Status eq 'Settled')")
  end

  test "orderby" do
    assert_parses_orderby("$orderby=Name")
    assert_parses_orderby("$orderby=Name asc")
    assert_parses_orderby("$orderby=Name desc")
    assert_parses_orderby("$orderby=Amount desc,Name asc")
    assert_parses_orderby("$orderby=Amount desc,Name asc,Date desc")
  end

  test "parse_query" do
    assert {:ok, %ExOdata4.Query{top: 50, skip: 0}} =
             Parser.parse_query("$top=50&$skip=0")

    assert {:ok, %ExOdata4.Query{top: 50, filter: [_ | _]}} =
             Parser.parse_query("$filter=Amount gt 1000&$top=50")

    assert {:ok, %ExOdata4.Query{filter: [_ | _], top: 50, skip: 0}} =
             Parser.parse_query("$filter=Amount gt 1000&$top=50&$skip=0")

    assert {:ok, %ExOdata4.Query{filter: [_ | _], top: 50, skip: 0, orderby: [_ | _]}} =
             Parser.parse_query("$filter=Amount gt 1000&$top=50&$skip=0&$orderby=Amount desc")
  end

  test "string function expressions parse" do
    assert_parses_filter("contains(Name, 'John')")
    assert_parses_filter("startswith(Name, 'John')")
    assert_parses_filter("endswith(Name, 'John')")
  end

  test "string functions produce correct AST" do
    alias ExOdata4.AST

    assert {:ok, [%AST.FunctionCall{name: :contains, args: [%AST.Field{name: "Name"}, %AST.Literal{type: :string, value: "John"}]}], "", _, _, _} =
             Parser.parse_filter("contains(Name, 'John')")

    assert {:ok, [%AST.FunctionCall{name: :startswith, args: [%AST.Field{name: "Status"}, %AST.Literal{type: :string, value: "act"}]}], "", _, _, _} =
             Parser.parse_filter("startswith(Status, 'act')")

    assert {:ok, [%AST.FunctionCall{name: :endswith, args: [%AST.Field{name: "Email"}, %AST.Literal{type: :string, value: ".com"}]}], "", _, _, _} =
             Parser.parse_filter("endswith(Email, '.com')")
  end

  test "string functions combined with logical operators" do
    assert_parses_filter("contains(Name, 'John') and Amount gt 100")
    assert_parses_filter("startswith(Status, 'act') or endswith(Email, '.com')")
    assert_parses_filter("contains(Name, 'John') and contains(Status, 'active')")
  end

  test "string functions in parse_query" do
    assert {:ok, %ExOdata4.Query{filter: [%ExOdata4.AST.FunctionCall{name: :contains}]}} =
             Parser.parse_query("$filter=contains(Name, 'John')")

    assert {:ok, %ExOdata4.Query{filter: [_ | _], top: 10}} =
             Parser.parse_query("$filter=contains(Name, 'John')&$top=10")
  end
end

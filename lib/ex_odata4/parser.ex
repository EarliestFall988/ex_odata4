defmodule ExOdata4.Parser do
  import NimbleParsec
  alias ExOdata4.AST
  alias ExOdata4.Parser.Literals
  alias ExOdata4.Parser.Expressions

  def parse_query(input) do
    parts = String.split(input, "&")

    Enum.reduce_while(parts, {:ok, %ExOdata4.Query{}}, fn part, {:ok, query} ->
      cond do
        String.starts_with?(part, "$filter=") ->
          case parse_filter(String.replace_prefix(part, "$filter=", "")) do
            {:ok, result, "", _, _, _} -> {:cont, {:ok, %{query | filter: result}}}
            _ -> {:halt, {:error, "invalid filter: #{part}"}}
          end

        String.starts_with?(part, "$top=") ->
          case parse_top(part) do
            {:ok, [value], "", _, _, _} -> {:cont, {:ok, %{query | top: value}}}
            _ -> {:halt, {:error, "invalid top: #{part}"}}
          end

        String.starts_with?(part, "$skip=") ->
          case parse_skip(part) do
            {:ok, [value], "", _, _, _} -> {:cont, {:ok, %{query | skip: value}}}
            _ -> {:halt, {:error, "invalid skip: #{part}"}}
          end

        String.starts_with?(part, "$orderby=") ->
          case parse_orderby(part) do
            {:ok, result, "", _, _, _} -> {:cont, {:ok, %{query | orderby: result}}}
            _ -> {:halt, {:error, "invalid orderby: #{part}"}}
          end

        true ->
          {:halt, {:error, "unknown query option: #{part}"}}
      end
    end)
  end

  defp build_binary_op(rest, args, context, _line, _offset) do
    [field_name, op, literal] = Enum.reverse(args)

    {rest,
     [
       %AST.BinaryOp{
         op: op,
         left: %AST.Field{name: field_name},
         right: literal
       }
     ], context}
  end

  defp build_logical_op(rest, [right, op, left], context, _line, _offset) do
    {rest, [%AST.BinaryOp{op: op, left: left, right: right}], context}
  end

  defp build_logical_op(rest, [single], context, _line, _offset) do
    {rest, [single], context}
  end

  defp null_literal(rest, [:null], context, _line, _offset) do
    {rest, [%AST.Literal{type: :null, value: nil}], context}
  end

  defp boolean_literal(rest, [:bool_true], context, _line, _offset) do
    {rest, [%AST.Literal{type: :boolean, value: true}], context}
  end

  defp boolean_literal(rest, [:bool_false], context, _line, _offset) do
    {rest, [%AST.Literal{type: :boolean, value: false}], context}
  end

  defp build_string_literal(rest, args, context, _line, _offset) do
    value = args |> Enum.reverse() |> Enum.join()
    {rest, [%AST.Literal{type: :string, value: value}], context}
  end

  defp build_decimal_literal(rest, args, context, _line, _offset) do
    {sign, rest_args} =
      case Enum.reverse(args) do
        ["-" | tail] -> {-1, tail}
        tail -> {1, tail}
      end

    [whole, frac] = rest_args
    value = String.to_float("#{whole}.#{frac}") * sign
    {rest, [%AST.Literal{type: :decimal, value: value}], context}
  end

  defp build_date_literal(rest, [day, month, year], context, _line, _offset) do
    {:ok, date} = Date.new(year, month, day)
    {rest, [%AST.Literal{type: :date, value: date}], context}
  end

  defp build_datetime_literal(rest, args, context, _line, _offset) do
    [year, month, day | time_and_tz] = Enum.reverse(args)
    {:ok, date} = Date.new(year, month, day)
    {rest, [%AST.Literal{type: :datetime, value: {date, time_and_tz}}], context}
  end

  defp build_guid_literal(rest, args, context, _line, _offset) do
    value = args |> Enum.reverse() |> Enum.join("-")
    {rest, [%AST.Literal{type: :guid, value: value}], context}
  end

  defp parse_integer_args(args) do
    case Enum.reverse(args) do
      ["-", n] -> -n
      [n] -> n
    end
  end

  # defp build_integer_literal(rest, args, context, _line, _offset) do
  #   {rest, [%AST.Literal{type: :integer, value: parse_integer_args(args)}], context}
  # end

  defp build_int32_literal(rest, args, context, _line, _offset) do
    {rest, [%AST.Literal{type: :integer, value: parse_integer_args(args)}], context}
  end

  defp build_int64_literal(rest, args, context, _line, _offset) do
    {rest, [%AST.Literal{type: :integer, value: parse_integer_args(args)}], context}
  end

  defparsec(:parse_literal, Literals.primitive_literal())

  defcombinatorp(
    :paren_expr,
    ignore(string("("))
    |> ignore(optional(Literals.whitespace()))
    |> parsec(:common_expr)
    |> ignore(optional(Literals.whitespace()))
    |> ignore(string(")"))
  )

  defcombinatorp(
    :common_expr,
    choice([
      parsec(:paren_expr),
      Expressions.comparison_expr()
    ])
    |> optional(
      ignore(Literals.rws())
      |> concat(Expressions.logical_op())
      |> ignore(Literals.rws())
      |> concat(parsec(:common_expr))
    )
    |> post_traverse({:build_logical_op, []})
  )

  defparsec(:parse_filter, parsec(:common_expr))

  defparsec(
    :parse_top,
    ignore(string("$top="))
    |> integer(min: 1)
  )

  defparsec(
    :parse_skip,
    ignore(string("$skip="))
    |> integer(min: 1)
  )

  defparsec(
    :parse_orderby,
    Expressions.orderby()
  )
end

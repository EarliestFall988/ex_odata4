defmodule ExOdata4.Parser.Expressions do
  import NimbleParsec
  alias ExOdata4.Parser.Literals

  def odata_identifier do
    utf8_string([?a..?z, ?A..?Z, ?_], 1)
    |> optional(utf8_string([?a..?z, ?A..?Z, ?_, ?0..?9], min: 1))
    |> reduce({Enum, :join, [""]})
  end

  def comparison_op do
    choice([
      string(" eq ") |> replace(:eq),
      string(" ne ") |> replace(:ne),
      string(" gt ") |> replace(:gt),
      string(" ge ") |> replace(:ge),
      string(" lt ") |> replace(:lt),
      string(" le ") |> replace(:le)
    ])
  end

  def logical_op do
    choice([
      string("and") |> replace(:and),
      string("or") |> replace(:or)
    ])
  end

  def comparison_expr do
    odata_identifier()
    |> concat(comparison_op())
    |> concat(Literals.primitive_literal())
    |> post_traverse({:build_binary_op, []})
  end

  def common_expr do
    comparison_expr()
    |> optional(
      ignore(Literals.rws())
      |> concat(logical_op())
      |> ignore(Literals.rws())
      |> concat(parsec(:common_expr))

    )
  end

  # expressions.ex
  def orderby_direction do
    choice([
      string("asc") |> replace(:asc),
      string("desc") |> replace(:desc)
    ])
  end

  def orderby_item do
    odata_identifier()
    |> optional(
      ignore(Literals.rws())
      |> concat(orderby_direction())
    )
  end

  def orderby do
    ignore(string("$orderby="))
    |> concat(orderby_item())
    |> repeat(
      ignore(string(","))
      |> concat(orderby_item())
    )
  end
end

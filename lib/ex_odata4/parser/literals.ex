defmodule ExOdata4.Parser.Literals do
  import NimbleParsec



  def whitespace do
    utf8_string([?\s, ?\t], min: 1)
  end

  def bws do
    optional(ignore(whitespace()))
  end

  def rws do
    whitespace() |> ignore()
  end

  def null_literal do
    string("null")
    |> replace(:null)
    |> post_traverse({:null_literal, []})
  end

  def boolean_literal do
    choice([
      string("true") |> replace(:bool_true),
      string("false") |> replace(:bool_false)
    ])
    |> post_traverse({:boolean_literal, []})
  end

  defp raw_integer do
    optional(string("-"))
    |> integer(min: 1)
  end

  def integer_literal do
    raw_integer()
    |> post_traverse({:build_integer_literal, []})
  end

  def int32_literal do
    raw_integer()
    |> post_traverse({:build_int32_literal, []})
  end

  def int64_literal do
    raw_integer()
    |> ignore(string("L"))
    |> post_traverse({:build_int64_literal, []})
  end

  def decimal_literal do
    optional(string("-"))
    |> integer(min: 1)
    |> ignore(string("."))
    |> integer(min: 1)
    |> post_traverse({:build_decimal_literal, []})
  end

  # 8HEXDIG "-" 4HEXDIG "-" 4HEXDIG "-" 4HEXDIG "-" 12HEXDIG
  def guid_literal do
    utf8_string([?0..?9, ?a..?f, ?A..?F], 8)
    |> ignore(string("-"))
    |> utf8_string([?0..?9, ?a..?f, ?A..?F], 4)
    |> ignore(string("-"))
    |> utf8_string([?0..?9, ?a..?f, ?A..?F], 4)
    |> ignore(string("-"))
    |> utf8_string([?0..?9, ?a..?f, ?A..?F], 4)
    |> ignore(string("-"))
    |> utf8_string([?0..?9, ?a..?f, ?A..?F], 12)
    |> post_traverse({:build_guid_literal, []})
  end

  def string_literal do
    ignore(string("'"))
    |> repeat(
      choice([
        # escaped quote → single quote
        string("''") |> replace("'"),
        # normal chars
        utf8_string([not: ?'], min: 1)
      ])
    )
    |> ignore(string("'"))
    |> post_traverse({:build_string_literal, []})
  end

  defp raw_date do
    integer(4)
    |> ignore(string("-"))
    |> integer(2)
    |> ignore(string("-"))
    |> integer(2)
  end

  def date_literal do
    raw_date()
    |> post_traverse({:build_date_literal, []})
  end

  def datetime_offset_literal do
    # ← raw, not date_literal()
    raw_date()
    |> ignore(string("T"))
    |> concat(time_of_day_literal())
    |> concat(timezone_offset())
    |> post_traverse({:build_datetime_literal, []})
  end

  defp time_of_day_literal do
    hour()
    |> ignore(string(":"))
    |> concat(minute())
    |> optional(
      ignore(string(":"))
      |> concat(second())
      |> optional(
        ignore(string("."))
        |> concat(fractional_seconds())
      )
    )
  end

  defp timezone_offset do
    choice([
      string("Z") |> replace(:utc),
      sign()
      |> concat(hour())
      |> ignore(string(":"))
      |> concat(minute())
    ])
  end

  defp sign do
    choice([
      string("+") |> replace(:positive),
      string("-") |> replace(:negative)
    ])
  end

  defp hour do
    choice([
      string("2") |> concat(utf8_string([?0..?3], 1)),
      utf8_string([?0..?1], 1) |> concat(utf8_string([?0..?9], 1))
    ])
  end

  defp minute do
    utf8_string([?0..?5], 1)
    |> concat(utf8_string([?0..?9], 1))
  end

  defp second do
    choice([
      string("60"),
      utf8_string([?0..?5], 1)
      |> concat(utf8_string([?0..?9], 1))
    ])
  end

  defp fractional_seconds do
    # 1*12DIGIT
    utf8_string([?0..?9], min: 1, max: 12)
  end

  def duration_literal do
    "TODO"
  end

  def enum_literal do
    "TODO"
  end

  def primitive_literal do
    choice([
      null_literal(),
      boolean_literal(),
      guid_literal(),
      datetime_offset_literal(),
      date_literal(),
      # decimal before int, really important for parsing
      decimal_literal(),
      int64_literal(),
      int32_literal(),
      string_literal()
      # duration_literal(),
      # enum_literal()
    ])
  end
end

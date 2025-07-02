defmodule Tunez.Music.Calculations.SecondsToMinutes do
  use Ash.Resource.Calculation

  @doc """
  This is much better than implementing `calculate/3`.

  > Why does this matter? Imagine if, instead of doing a quick string manipulation for our calculation, we were doing something really complicated for every track on an album, and we were loading a lot of records at once, such as a band with a huge discography. We’d be running calculations in a big loop that would be slow and inefficient.
  > Why are we talking about this now? Because writing calculations in Elixir using calculate/3 is really useful, but it’s not the optimal approach.
  """
  @impl true
  def expression(_opts, _context) do
    expr(
      fragment("? / 60 || to_char(? * interval '1s', ':SS')", duration_seconds, duration_seconds)
    )
  end

  # @impl true
  # def calculate(tracks, _opts, _context) do
  # 	Enum.map(tracks, fn %{duration_seconds: duration} ->
  # 		seconds =
  # 		duration
  # 		|> rem(60)
  # 		|> Integer.to_string()
  # 		|> String.pad_leading(2, "0")
  # 		"#{div(duration, 60)}:#{seconds}"
  # 	end)
  # end
end

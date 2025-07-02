defmodule Tunez.Music.Changes.MinutesToSeconds do
  use Ash.Resource.Change

  @impl true
  def atomic(changeset, opts, context) do
    {:ok, change(changeset, opts, context)}
  end

  @impl true
  def change(changeset, _opts, _context) do
    {:ok, duration} = Ash.Changeset.fetch_argument(changeset, :duration)

    with :ok <- ensure_valid_format(duration),
         :ok <- ensure_valid_format(duration) do
      changeset
      |> Ash.Changeset.change_attribute(:duration_seconds, to_seconds(duration))
    else
      {:error, :format} ->
        Ash.Changeset.add_error(changeset, field: :duration, message: "use MM:SS format")

      {:error, :value} ->
        Ash.Changeset.add_error(changeset,
          field: :duration,
          message: "must be at least 1 second long"
        )
    end
  end

  defp ensure_valid_format(duration) do
    cond do
      duration in ["0:00", "00:00"] ->
        {:error, :value}

      not String.match?(duration, ~r/^\d+:\d{2}$/) ->
        {:error, :format}

      String.match?(duration, ~r/^\d+:\d{2}$/) ->
        :ok

      true ->
        :ok
    end
  end

  defp to_seconds(duration) do
    [minutes, seconds] = String.split(duration, ":", parts: 2)
    String.to_integer(minutes) * 60 + String.to_integer(seconds)
  end
end

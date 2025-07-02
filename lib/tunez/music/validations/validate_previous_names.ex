defmodule Tunez.Music.Validations.ValidatePreviousNames do
  use Ash.Resource.Validation

  @impl true
  def init(opts) do
    if is_atom(opts[:attribute]) do
      {:ok, opts}
    else
      {:error, "attribute must be atom"}
    end
  end

  @impl true
  def validate(changeset, _opts, _context) do
    new_name = Ash.Changeset.get_attribute(changeset, :name)
    previous_names = Ash.Changeset.get_data(changeset, :previous_names)

    if new_name not in previous_names do
      :ok
    else
      {:error, field: :name, message: "Already in previous names"}
    end
  end
end

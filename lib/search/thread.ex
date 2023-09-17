defmodule Search.Thread do
  use Ecto.Schema

  import Ecto.Changeset

  schema "threads" do
    field(:title, :string)

    has_many(:messages, Search.Message, preload_order: [asc: :inserted_at])

    timestamps()
  end

  @required_attrs [:title]

  def changeset(thread, params \\ %{}) do
    thread
    |> cast(params, @required_attrs)
    |> validate_required(@required_attrs)
  end
end

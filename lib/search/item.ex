defmodule Search.Item do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query
  import Pgvector.Ecto.Query

  alias __MODULE__

  schema "items" do
    field :text, :string
    field :embedding, Pgvector.Ecto.Vector

    timestamps()
  end

  @required_attrs [:embedding, :text]

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, @required_attrs)
    |> validate_required(@required_attrs)
  end

  def search(embedding) do
    Search.Repo.all(from i in Item, order_by: l2_distance(i.embedding, ^embedding), limit: 2)
  end
end

defmodule Search.Message do
  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset
  import Pgvector.Ecto.Query

  alias __MODULE__

  schema "messages" do
    field(:text, :string)
    field(:embedding, Pgvector.Ecto.Vector)

    belongs_to(:thread, Search.Thread)
    belongs_to(:user, Search.User)

    timestamps()
  end

  @required_fields [:thread_id, :user_id, :text]

  def changeset(message, params \\ %{}) do
    message
    |> cast(params, @required_attrs)
    |> validate_required(@required_attrs)
  end

  def search(embedding) do
    Search.Repo.all(from i in Message, order_by: cosine_distance(i.embedding, ^embedding), limit: 1)
  end
end

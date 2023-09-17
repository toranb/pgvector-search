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

  @required_attrs [:thread_id, :user_id, :text]
  @optional_attrs [:embedding]

  def changeset(message, params \\ %{}) do
    message
    |> cast(params, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  def search(embedding) do
    Search.Repo.all(from i in Message, order_by: cosine_distance(i.embedding, ^embedding), limit: 1)
    |> List.first()
  end
end

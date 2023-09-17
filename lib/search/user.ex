defmodule Search.User do
  use Ecto.Schema

  import Ecto.Changeset

  schema "users" do
    field(:name, :string)

    has_many(:messages, Search.Message)

    timestamps()
  end

  @required_attrs [:name]

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, @required_attrs)
    |> validate_required(@required_attrs)
  end
end

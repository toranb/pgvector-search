defmodule Search.Repo.Migrations.AddThreadIndex do
  use Ecto.Migration

  def change do
    create index(:messages, [:thread_id])
  end
end

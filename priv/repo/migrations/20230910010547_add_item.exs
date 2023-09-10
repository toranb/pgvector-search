defmodule Search.Repo.Migrations.AddItem do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :text, :text
      add :embedding, :vector, size: 384

      timestamps()
    end

    create index("items", ["embedding vector_l2_ops"], using: :hnsw)
  end
end

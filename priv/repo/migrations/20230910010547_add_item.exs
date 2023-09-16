defmodule Search.Repo.Migrations.AddItem do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :text, :text
      add :embedding, :vector, size: 768

      timestamps()
    end

    create index("items", ["embedding vector_cosine_ops"], using: :hnsw)
  end
end

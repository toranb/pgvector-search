defmodule Search.Repo.Migrations.DropPreviousEmbeddingIndex do
  use Ecto.Migration

  def change do
    drop index("messages", ["embedding vector_cosine_ops"])
  end
end

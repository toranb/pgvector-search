defmodule Search.Repo.Migrations.AddThreadsMessages do
  use Ecto.Migration

  def change do
    create table(:threads) do
      add :title, :string, null: false

      timestamps()
    end

    create table(:users) do
      add :name, :string, null: false

      timestamps()
    end

    create table(:messages) do
      add :text, :text, null: false
      add :embedding, :vector, size: 768

      add :thread_id, references(:threads), null: false
      add :user_id, references(:users), null: false

      timestamps()
    end

    create index("messages", ["embedding vector_ip_ops"], using: :hnsw)
  end
end

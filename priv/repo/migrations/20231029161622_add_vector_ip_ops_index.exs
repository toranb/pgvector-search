defmodule Search.Repo.Migrations.AddVectorIpOpsIndex do
  use Ecto.Migration

  def change do
    create index("messages", ["embedding vector_ip_ops"], using: :hnsw)
  end
end

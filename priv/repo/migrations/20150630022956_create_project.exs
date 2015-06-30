defmodule Pxblog.Repo.Migrations.CreateProject do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :title, :string
      add :url, :string
      add :description, :text

      timestamps
    end

  end
end

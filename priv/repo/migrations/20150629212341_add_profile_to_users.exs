defmodule Pxblog.Repo.Migrations.AddProfileToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :profile, :text
    end
  end
end

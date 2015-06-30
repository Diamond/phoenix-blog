defmodule Pxblog.Repo.Migrations.AddUserIdToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :user_id, references(:users)
    end
  end
end

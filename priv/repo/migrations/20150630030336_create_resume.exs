defmodule Pxblog.Repo.Migrations.CreateResume do
  use Ecto.Migration

  def change do
    create table(:resumes) do
      add :body, :text

      timestamps
    end

  end
end

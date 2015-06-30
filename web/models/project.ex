defmodule Pxblog.Project do
  use Pxblog.Web, :model

  schema "projects" do
    belongs_to :user, Pxblog.User

    field :title, :string
    field :url, :string
    field :description, :string

    timestamps
  end

  @required_fields ~w(title url description)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If `params` are nil, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def for_user(user_id) do
    posts = from p in Pxblog.Project,
      order_by: [desc: p.updated_at],
      where: p.user_id == ^user_id,
      preload: [:user]
  end
end

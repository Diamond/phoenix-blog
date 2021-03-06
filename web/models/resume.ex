defmodule Pxblog.Resume do
  use Pxblog.Web, :model

  schema "resumes" do
    belongs_to :user, Pxblog.User
    field :body, :string

    timestamps
  end

  @required_fields ~w(body)
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
    posts = from r in Pxblog.Resume,
      order_by: [desc: r.updated_at],
      where: r.user_id == ^user_id,
      preload: [:user]
  end
end

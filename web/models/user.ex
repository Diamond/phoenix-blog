defmodule Pxblog.User do
  use Pxblog.Web, :model
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]
  import Ecto.Query

  schema "users" do
    has_many :posts, Pxblog.Post
    has_many :projects, Pxblog.Project

    field :username, :string
    field :email, :string
    field :password_digest, :string
    field :profile, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps
  end

  @required_fields ~w(username email password password_confirmation profile)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If `params` are nil, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_confirmation(:password, message: "passwords do not match")
    |> hash_password
  end

  def hash_password(changeset) do
    if changeset.params["password"] do
      changeset
      |> put_change(:password_digest, hashpwsalt(changeset.params["password"]))
    else
      changeset
    end
  end
end

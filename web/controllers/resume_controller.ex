defmodule Pxblog.ResumeController do
  use Pxblog.Web, :controller

  alias Pxblog.Resume

  plug :check_permissions when action in [:new, :create, :edit, :update]
  plug :scrub_params, "resume" when action in [:create, :update]

  def index(conn, %{"user_id" => user_id}) do
    if Repo.get User, user_id do
      resumes = user_id
      |> Resume.for_user
      |> Repo.all
      |> Repo.limit(1)
      render(conn, "index.html", resumes: resumes)
    else
      conn
      |> put_flash(:error, "Invalid user specified!")
      |> redirect(to: page_path(conn, :index))
    end
  end

  def index(conn, _params) do
    resumes = Repo.all from r in Resume,
      order_by: [desc: r.updated_at],
      preload: [:user],
      limit: 1
    render(conn, "index.html", resumes: resumes)
  end

  def new(conn, _params) do
    changeset = Resume.changeset(%Resume{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"resume" => resume_params}) do
    new_resume = build(get_session(conn, :current_user), :resumes)
    changeset = Resume.changeset(new_resume, resume_params)

    if changeset.valid? do
      Repo.insert(changeset)

      conn
      |> put_flash(:info, "Resume created successfully.")
      |> redirect(to: resume_path(conn, :index))
    else
      render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    resume = Repo.get(Resume, id)
    render(conn, "show.html", resume: resume)
  end

  def edit(conn, %{"id" => id}) do
    resume = Repo.get(Resume, id)
    changeset = Resume.changeset(resume)
    render(conn, "edit.html", resume: resume, changeset: changeset)
  end

  def update(conn, %{"id" => id, "resume" => resume_params}) do
    resume = Repo.get(Resume, id)
    changeset = Resume.changeset(resume, resume_params)

    if changeset.valid? do
      Repo.update(changeset)

      conn
      |> put_flash(:info, "Resume updated successfully.")
      |> redirect(to: resume_path(conn, :index))
    else
      render(conn, "edit.html", resume: resume, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    resume = Repo.get(Resume, id)
    Repo.delete(resume)

    conn
    |> put_flash(:info, "Resume deleted successfully.")
    |> redirect(to: resume_path(conn, :index))
  end

  defp check_permissions(conn, _params) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to do that!")
      |> redirect(to: page_path(conn, :index))
      |> halt
    end
  end
end

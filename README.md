## Step 1: Let's add Posts ##



	mix phoenix.new pxblog
		# Y, Y
	cd pxblog
	iex -S mix phoenix.server
	mix phoenix.gen.html Post posts title:string body:text

	# postgres create role instructions

	# open up web/router.ex, add:
	resources "/posts", PostController

	mix ecto.create
	mix ecto.migrate
	# [info] == Running Pxblog.Repo.Migrations.CreatePost.change/0 forward
	# [info] create table posts
	# [info] == Migrated in 0.0s

	# Restart server
	# Visit localhost:4000/posts

## Step 2: Let's add Users ##

	git init
	git add .
	git commit -m "Step 1 complete"

	mix phoenix.gen.html User users username:string email:string password_digest:string
	# open up web/router.ex, add:
	resources "/users", UserController

	mix ecto.migrate
	# Compiled lib/pxblog.ex
	# Compiled web/models/user.ex
	# Compiled web/views/error_view.ex
	# Compiled web/router.ex
	# Compiled web/views/page_view.ex
	# Compiled web/views/layout_view.ex
	# Compiled web/controllers/page_controller.ex
	# Compiled web/controllers/user_controller.ex
	# Compiled web/controllers/post_controller.ex
	# Compiled lib/pxblog/endpoint.ex
	# Compiled web/views/post_view.ex
	# Compiled web/views/user_view.ex
	# Generated pxblog app
	# [info] == Running Pxblog.Repo.Migrations.CreateUser.change/0 forward
	# [info] create table users
	# [info] == Migrated in 0.0s

	# Restart server
	# Visit localhost:4000/users

## Step 3: Saving a Password Hash instead of a Password ##

When we visit `/users/new`, we see three fields: __Username__, __Email__, and __PasswordDigest__. But when you register on other sites, you would enter a password and a password confirmation! How can we correct this?

In `web/templates/user/form.html.eex`, modify the file from:

	  <div class="form-group">
	    <label>PasswordDigest</label>
	    <%= text_input f, :password_digest, class: "form-control" %>
	  </div>

To:

	  <div class="form-group">
	    <label>Password</label>
	    <%= password_input f, :password, class: "form-control" %>
	  </div>

	  <div class="form-group">
	    <label>Password Confirmation</label>
	    <%= password_input f, :password_confirmation, class: "form-control" %>
	  </div>

Refresh the page (should happen automatically), enter user details, hit submit.

Error:

	Oops, something went wrong! Please check the errors below:

	Password digest can't be blank

This is because we're creating a password and password confirmation but nothing is being done to create the actual password_digest. Let's write some code to do this. First, we're going to modify the actual schema to do something new:

In `web/models/user.ex`:

	  schema "users" do
    	field :username, :string
    	field :email, :string
	    field :password_digest, :string
    	field :password, :string, virtual: true
	    field :password_confirmation, :string, virtual: true

    	timestamps
	  end

Note the addition of the two fields, `:password` and `:password_confirmation`. We're declaring these as __virtual__ fields, as these do not actually exist in our database but need to exist as properties in our User struct. This also allows us to apply transformations in our changeset function.

We then modify the list of required fields to include password and password_confirmation.

	  @required_fields ~w(username email password password_confirmation)

And finally, we modify the changeset function to do this data transformation on the fly.

	  def changeset(model, params \\ :empty) do
	    model
	    |> cast(params, @required_fields, @optional_fields)
	    |> hash_password
	  end

	  def hash_password(changeset) do
	  	changeset
	  	|> put_change(:password_digest, "ABCDE")
	  end

Right now we're just stubbing out the behavior of our hashing function. The first step is to make sure that we can modify our changeset as we go along. Let's verify this behavior first. Go back to `http://localhost:4000/users` in our browser, click on "New user", and create a new user with any details. When we hit the index page again, we should expect to see the user created with a password_digest value of "ABCDE".

This is a great step, but not terribly great for security! Let's modify our hashes to be real password hashes with Bcrypt, courtesy of the `comeonin` library.

First, open up `mix.exs` and add the following to our application definition:

	  def application do
	    [mod: {Pxblog, []},
	     applications: [:phoenix, :phoenix_html, :cowboy, :logger,
	                    :phoenix_ecto, :postgrex, :comeonin]]
	  end

Note the ":comeonin" addition above. And also modify our deps definition:

	  defp deps do
	    [{:phoenix, "~> 0.13"},
	     {:phoenix_ecto, "~> 0.4"},
	     {:postgrex, ">= 0.0.0"},
	     {:phoenix_html, "~> 1.0"},
	     {:phoenix_live_reload, "~> 0.4", only: :dev},
	     {:cowboy, "~> 1.0"},
	     {:comeonin, "~> 0.10"}]
	  end

Same here, note the addition of `{:comeonin, "~> 0.10"}`. Now, let's shut down the server we've been running and run `mix deps.get`. If all goes well (it should!), then now you should be able to rerun `iex -S mix phoenix.server` to restart your server.

Our old hash_password method is neat, but we need it to actually hash our password. Since we've added the comeonin library, which provides us a nice Bcrypt module with a hashpwsalt method, so let's import that into our User model.

In `web/models/user.ex`, add the following line to the top just under our `use Pxblog.Web, :model` line:

	import Comeonin.Bcrypt, only: [hashpwsalt: 1]

And now we're going to modify our __hash_password__ method to work.

	  def hash_password(changeset) do
	    if changeset.params["password"] do
	      changeset
	      |>  put_change(:password_digest, hashpwsalt(changeset.params["password"]))
	    else
	      changeset
	    end
	  end

Let's try creating a user again! This time, after entering in our data for username, email, password, and password confirmation, we should see a Bcrypt digest show up in the password_digest field!

## Step 4: Let's log in! ##

### Step 4a: The Foundation ###

Let's add a new controller, `SessionController` and an accompanying view, `SessionView`. We'll start simple and build our way up to a better implementation over time.

Create `web/controllers/session_controller.ex`:

	defmodule Pxblog.SessionController do
	  use Pxblog.Web, :controller

	  plug :action

	  def new(conn, _params) do
	    render conn, "new.html"
	  end
	end

Create `web/views/session_view.ex`:

	defmodule Pxblog.SessionView do
	  use Pxblog.Web, :view
	end

Create `web/templates/session/new.html.eex`:

	<h2>Login</h2>

And finally, let's update the router to include this new controller. Add the following line to our "/" scope:

	resources "/sessions", SessionController, only: [:new]

The only route we want to expose for the time being is new, so we're going to limit it just to that. Again, we want to keep things simple and build up from a stable foundation.

Now let's visit `http://localhost:4000/sessions/new`, we should expect to see the Phoenix framework header and the "Login" header.

Let's give it a real form. Create `web/templates/session/form.html.eex`:

	<%= form_for @changeset, @action, fn f -> %>
	  <%= if f.errors != [] do %>
	    <div class="alert alert-danger">
	      <p>Oops, something went wrong! Please check the errors below:</p>
	      <ul>
	        <%= for {attr, message} <- f.errors do %>
	          <li><%= humanize(attr) %> <%= message %></li>
	        <% end %>
	      </ul>
	    </div>
	  <% end %>

	  <div class="form-group">
	    <label>Username</label>
	    <%= text_input f, :title, class: "form-control" %>
	  </div>

	  <div class="form-group">
	    <label>Password</label>
	    <%= password_input f, :password, class: "form-control" %>
	  </div>

	  <div class="form-group">
	    <%= submit "Submit", class: "btn btn-primary" %>
	  </div>
	<% end %>

And modify `web/templates/session/new.html.eex` to call our new form by adding one line:

	<%= render "form.html", changeset: @changeset, action: post_path(@conn, :create) %>

The autoreloading will end up displaying an error page right now because we haven't actually defined `@changeset`, which as you may guess needs to be a changeset. Since we're working with the member object, which has `username` and `password` fields already on it, let's use that!

In `web/controllers/session_controller.ex`, we need to alias the User model to be able to use it further. At the top of our class, under our `use Pxblog.Web, :controller` line, add the following:

	alias Pxblog.User

And in the __new__ function, modify the call to render as follows:

	render conn, "new.html", changeset: User.changeset(%User{})

We need to pass it the connection, the template we're rendering (minus the eex), and a list of additional variables that should be exposed to our templates. In this case, we want to expose @changeset, so we specify `changeset:` here, and we give it the Ecto changeset for the User with a blank User struct. (`%User{}` is a User Struct with no values set)

Refresh now and we should see the login form with no errors!

### Step 4b: Submitting our credentials ###

We've gotten part of the way there. Now let's make it so we can actually post our login details and set the session.

Let's update our routes to allow posting to create.

In `web/router.ex`, change our reference to SessionController to also include `:create`.

	resources "/sessions", SessionController, only: [:new, :create]

In `web/controllers/session_controller.ex`, we need to import a new function, `checkpw` from Comeonin's Bcrypt module. We do this via the following line:

	import Comeonin.Bcrypt, only: [checkpw: 2]

(Import from the Comeonin.Bcrypt module, only the checkpw function with an arity of 2). And then let's add a scrub_params plug to deal with User data. Under `plug :action`, add:

	plug :scrub_params, "user" when action in [:create]

Scrub params is very similar to Rails' strong parameters. You feed it the connection object (this happens automatically with the call to plug, as plug is a contract that guarantees a connection object goes in and is returned), and then the "Required Key" parameter is passed along (in our case, "user").

And let's add our function to handle the create post. We're going to add this to the bottom of our SessionController module. There's going to be a lot of code here, so we'll take it piece by piece.

In `web/controllers/session_controller.ex`:

	  def create(conn, %{"user" => user_params}) do
	    user = Repo.get_by(User, username: user_params["username"])
	    user
	    |> sign_in(user_params["password"], conn)
	  end

The first bit of this code, `Repo.get_by(User, username: user_params["username"])` pulls the first applicable `User` from our Ecto Repo that has a matching username, or will otherwise return `nil`.

Here is some output to verify this behavior:

	iex(3)> Repo.get_by(User, username: "flibbity")
	[debug] SELECT u0."id", u0."username", u0."email", u0."password_digest", u0."inserted_at", u0."updated_at" FROM "users" AS u0 WHERE (u0."username" = $1) ["flibbity"] OK query=0.7ms
	nil

	iex(4)> Repo.get_by(User, username: "test")
	[debug] SELECT u0."id", u0."username", u0."email", u0."password_digest", u0."inserted_at", u0."updated_at" FROM "users" AS u0 WHERE (u0."username" = $1) ["test"] OK query=0.8ms
	%Pxblog.User{__meta__: %Ecto.Schema.Metadata{source: "users", state: :loaded},
	 email: "test", id: 15,
	 inserted_at: %Ecto.DateTime{day: 24, hour: 19, min: 6, month: 6, sec: 14,
	  usec: 0, year: 2015}, password: nil, password_confirmation: nil,
	 password_digest: "$2b$12$RRkTZiUoPVuIHMCJd7yZUOnAptSFyM9Hw3Aa88ik4erEsXTZQmwu2",
	 updated_at: %Ecto.DateTime{day: 24, hour: 19, min: 6, month: 6, sec: 14,
	  usec: 0, year: 2015}, username: "test"}

We then take the user, and chain that user into a sign_in method. We haven't written that yet, so let's do so!

	  defp sign_in(user, password, conn) when is_nil(user) do
	    conn
	    |> put_flash(:error, "Invalid username/password combination!")
	    |> redirect(to: page_path(conn, :index))
	  end

	  defp sign_in(user, password, conn) do
	    if checkpw(password, user.password_digest) do
	      conn
	      |> put_session(:current_user, user)
	      |> put_flash(:info, "Sign in successfull!")
	      |> redirect(to: page_path(conn, :index))
	    else
	      conn
	      |> put_session(:current_user, nil)
	      |> put_flash(:error, "Invalid username/password combination!")
	      |> redirect(to: page_path(conn, :index))
	    end
	  end
	end

The first thing to notice is the order that these methods are defined in. The first of these methods has a `guard clause` attached to it, so that method will only be executed when that guard clause is true, so if the user is nil, we redirect back to the index of the page (root) path with an appropriate flash message.

The second method will get called if the guard clause is false and will handle all other scenarios. We check the result of that `checkpw` function, and if it is true, we set the user to the current_user session variable and redirect with a success message. Otherwise, we clear out the current user session, set an error message, and redirect back to the root.

If we return to our login page `localhost:4000/sessions/new`, we should be able to test out login with a valid set of credentials and invalid credentials and see the appropriate error messages! Let's modify our layout to display a message or a link depending on if the member is logged in or not.

In `web/templates/layout/application.html.eex`, instead of the "Get Started" link, let's do the following:

	      <li>
            <% user = Plug.Conn.get_session(@conn, :current_user) %>
            <%= if user do %>
              Logged in as
              <strong><%= user.username %></strong>
              <br>
              <%= link "Log out", to: session_path(@conn, :delete, user), method: :delete %>
            <% else %>
              <%= link "Log in", to: session_path(@conn, :new) %>
            <% end %>
          </li>

Again, let's step through this piece by piece. One of the first things we need to do is figure out who the current user is, assuming they're logged in. Again, we're going with a simple first, refactor later approach, so for right now we're going to just set a user object from the session right in our template. `get_session` is part of the `Plug.Conn` object. If the user exists (this takes advantage of Elixir's Ruby-like truthiness values in that `nil` will return false here.)

If the user is logged in, we'll also want to provide a __logout__ link as well. Even those this does not exist yet, it will eventually need to exist, so for right now we're going to send it along. We'll treat a session like a resource, so to logout, we'll "delete" the session, so we'll provide a link to it here.

We also want to output the current user's username. We're storing the user struct in the `:current_user` session variable, so we can just access the username as user.username.

If we could not find the user, then we'll just provide the login link. Again, we're treating sessions like a resource here, so "new" will provide the appropriate route to create a new session.

Let's add our delete route as well to keep Phoenix happy!

In `web/router.ex`, we'll modify our "sessions" route to also allow `:delete`:

	resources "/sessions", SessionController, only: [:new, :create, :delete]

And let's modify the controller as well. In `web/controllers/session_controller.ex`, add the following:

	def delete(conn, _params) do
		conn
	      |> delete_session(:current_user)
	      |> put_flash(:info, "Signed out successfull!")
	      |> redirect(to: page_path(conn, :index))
	end

Since we're just deleting the `:current_user` key, we don't actually care what the params are, so we mark those as unused with an underscore. We set a flash message to make the UI a little more clear to the user and redirect back to our root route.

### Step 5: Adding our Posts ###

Let's go back to our `Post` object and modify it to be associated with a `User`. The first thing we need to do is modify the `Post` database table to include a `user_id`.

First, we need to run a command to generate our migration. Let's run the following in the terminal:

	mix ecto.gen.migration add_user_to_posts

And we should see a bunch of output ending in:

	Generated pxblog app
	* creating priv/repo/migrations
	* creating priv/repo/migrations/20150626195615_add_user_to_posts.exs

Please note that the timestamp is going to be different for you. That's okay! I'm going to use the above example, but ultimately you just want the migration that ends in that migration name (in our case, that's `add_user_to_posts.exs`. Let's modify that file. In `priv/repo/migrations/20150626195615_add_user_to_posts.exs`:

	defmodule Pxblog.Repo.Migrations.AddUserToPosts do
	  use Ecto.Migration

	  def change do
	    alter table(:posts) do
	      add :user_id, references(:users)
	    end
	  end
	end

We also need to modify our `Post` model and `User` model to reference each other appropriately. In the 'schema' section for `web/models/post.ex`, we add the following line to set up the "belongs to" relationship between a post and its user.

	belongs_to :user, Pxblog.User

In addition, let's add `user_id` to the list of required fields for a `Post`.

	@required_fields ~w(title body user_id)

And do the reverse set up in `web/models/user.ex`:

	has_many :posts, Pxblog.Post

We will now need to modify our create action to only create posts for a user. To do so, we'll need to take advantage of Ecto's `build` function. At the top of our create function in `web/controllers/post_controller.ex`, we're going to modify the `Post.changeset` call to look like the following:

	new_post = build(get_session(conn, :current_user), :posts)
	changeset = Post.changeset(new_post, post_params)

Let's make sure the index can find all of the posts from a particular user. Open up `web/models/post.ex` and add the following:

	def for_user(user_id) do
	  posts = from p in Pxblog.Post,
	 		   where: p.user_id == ^user_id,
	          order_by: [desc: p.created_at],
             preload: [:user]
	end

Let's talk about what we're actually doing here. Ecto models provide us a Linq-style query-writing interface, so we're going to use this here. We're going to set up an alias to our table (from the model) with the `from` keyword.

We're then going to specify the actual criteria to filter our posts on. Here, we're going to filter on the user id, so we specify a `where` criteria. We're using Elixir code here, not SQL, so we need to use `==` in our condition. In addition, we have to specify a ^ on the parameter we're searching for so that we don't end up pattern matching.

Next, we're specifying an order for our posts, since typically with a blog you want the posts that were created most recently first. Order is typically presented as a keyword list, specifying either `asc:` or `desc:` along with the aliased column. (`p` being our alias, `created_at` being our column).

The last piece of this, `preload: [:user]` tells Ecto to preload the associated objects that this query is going to pull in to avoid us performing an N+1 query and instead fetching everything in just a single query. The preload directive takes an array of symbols that need to be associated with the model's associations.

And let's go into our index function in `web/controllers/post_controller.ex` and modify it to do the following:

	def index(conn, _params) do
	  user = get_session(conn, :current_user)
	  posts = user.id
	  |> Post.for_user
	  |> Repo.all
	  render(conn, "index.html", posts: posts)
	end

Hooray! We now have posts visible for the current user! There's zero authentication going on here and we want to be able to view someone else's posts too, but this is a fine start!

### Step 6: Nesting our resources ###

Being able to see our own posts as a user is neat and a good demonstration of our database models and their relationships, but it's not terribly useful in the long run. Let's make our blog a bit more usable by having both a list of all blog posts in general, as well as all blog posts from a particular user.

The good news is that this is actually a pretty easy thing to do in Phoenix. Let's open up `web/router.ex`, and modify our route structure to match as follows:

    scope "/", Pxblog do
	    pipe_through :browser # Use the default browser stack

	    get "/", PageController, :index
	    resources "/posts", PostController
	    resources "/users", UserController do
	      resources "/posts", PostController
	    end
	    resources "/sessions", SessionController, only: [:new, :create, :delete]
    end

You're probably wondering why we're duplicating ourselves on the listing of our posts resource. The short version is that we want two ways to fetch our posts: all of the posts for a particular author, or all of the posts in general.

Let's change the `index` method to either fetch us all of the posts for a user or all of them total.

In `web/controllers/post_controller.ex`:

	def index(conn, params) do
   		posts = if params["user_id"] do
      		params["user_id"]
      		|> Post.for_user
      		|> Repo.all
    	else
      		Repo.all from p in Post,
        	order_by: [desc: p.updated_at],
        	preload: [:user]
    	end
    	render(conn, "index.html", posts: posts)
	end

Finally, let's change the listing on our index page to include the author. Let's open up `web/templates/post/index.html.eex`, and modify our table header to include:

	<th>Author</th>

And modify the table body to include:

    <td><%= link post.user.username, to: user_post_path(@conn, :index, post.user.id) %></td>

This will give us a link to view all posts from a particular author. One issue we still have, however, is that we can attempt to view posts from a completely invalid author, which seems pretty gross. Let's fix that. We'll go back to `web/controllers/post_controller.ex`:

	def index(conn, params) do
		if params["user_id"] && (!Repo.get User, params["user_id"]) do
       	conn
      		|> put_flash(:error, "Invalid user specified!")
      		|> redirect(to: page_path(conn, :index))
	    else
	      posts = if params["user_id"] do
	        params["user_id"]
	        |> Post.for_user
	        |> Repo.all
	      else
	        Repo.all from p in Post,
	          order_by: [desc: p.updated_at],
	          preload: [:user]
	      end
	      render(conn, "index.html", posts: posts)
	    end
	end

The biggest addition here is the first condition in the method. If the user_id is set and we cannot find a valid user for that user_id, then we need to send an error message and redirect back to the main index. Simple! And when we go back and test it, we see the error message exactly as we expected to! Awesome!

### Step 7: Refactoring our Controller ###

Our index method in our controller is getting pretty messy. Elixir gives us the ability to deconstruct and pattern match in our functions, and Phoenix is no different, so let's take advantage of this!

	  def index(conn, %{"user_id" => user_id}) do
	    if Repo.get User, user_id do
	      posts = user_id
	      |> Post.for_user
	      |> Repo.all
	      render(conn, "index.html", posts: posts)
	    else
	      conn
	      |> put_flash(:error, "Invalid user specified!")
	      |> redirect(to: page_path(conn, :index))
	    end
	  end

	  def index(conn, _params) do
	    posts = Repo.all from p in Post,
	      order_by: [desc: p.updated_at],
	      preload: [:user]
	    render(conn, "index.html", posts: posts)
	  end

Our first definition of index will only be hit when we have a user_id in our params list. If we don't, we'll instead skip to the second index definition which is intended for us not having specified a user. Note that we're back to marking params with an underscore in the second definition because it's not necessary anymore.

### Step 8: Authorizing Users with a plug ###

Anyone coming from a Rails background (or any web development background for that matter) is probably cringing at the idea of fetching information out of our session in the middle of our template. Not only that, but this code is not terribly reusable, so let's fix that. Phoenix has a concept of Plugs. A plug is a contract which very simply requires that it accepts a connection object and returns a connection object. So, let's write a plug that will give us simpler access to the current user that we can use in the templates.

Let's create a new file, `lib/pxblog/current_user.ex`:

	defmodule Pxblog.CurrentUser do
	  import Plug.Conn
	  import Plug.Session

	  def init(default), do: default

	  def call(conn, _default) do
	    current_user = get_session(conn, :current_user)
	    if current_user do
	      assign(conn, :current_user, current_user)
	    else
	      conn
	    end
	  end
	end

We include the Connection Plug to define our standard interface and the Session Plug to access the session. We write an init method that sets default values for options (but in this case doesn't do anything other than return options). Now that we've written our plug, let's...well, plug it in! (Sorry, that will hopefully be the last of those). Let's open up `web/router.ex` and add the following to our Browser Pipeline:

	  pipeline :browser do
	    plug :accepts, ["html"]
	    plug :fetch_session
	    plug :fetch_flash
	    plug :protect_from_forgery
	    plug Pxblog.CurrentUser
	  end

We have a little more work to do. Let's make this accessible to the application's templates. We'll open up `web/views/layout_view.ex` and add the following:

	def current_user(conn) do
		conn.assigns[:current_user]
	end

And finally, let's clean up our template a little bit using this new plug. Open up `web/templates/layout/application.html.eex`. Where we set the current user with that icky conn.session stuff, instead we write:

	<% user = current_user(@conn) %>

Now the view can easily grab the current user, and if we need the current user in any controller, we can fetch it from the conn.assigns value under the `:current_user` key.

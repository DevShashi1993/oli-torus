# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

default_sha = if Mix.env == :dev, do: "DEV BUILD", else: "UNKNOWN BUILD"
config :oli,
  ecto_repos: [Oli.Repo],
  build: %{
    version: Mix.Project.config[:version],
    sha: System.get_env("SHA", default_sha),
    date: DateTime.now!("Etc/UTC"),
    env: Mix.env,
  },
  local_activity_manifests: Path.wildcard(File.cwd! <> "/assets/src/components/activities/*/manifest.json")
    |> Enum.map(&File.read!/1)

# Configures the endpoint
config :oli, OliWeb.Endpoint,
  live_view: [signing_salt: System.get_env("LIVE_VIEW_SALT") || "LIVE_VIEW_SALT"],
  url: [host: "localhost"],
  secret_key_base: "GE9cpXBwVXNaplyUCYbIWqERmC/OlcR5iVMwLX9/W7gzQRxkD1ETjda9E0jW/BW1",
  render_errors: [view: OliWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Oli.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure OAuth
config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile", callback_params: ["type"]]},
    facebook: {Ueberauth.Strategy.Facebook, [default_scope: "email,public_profile", callback_params: ["type"]]},
    identity: {Ueberauth.Strategy.Identity, [
      callback_methods: ["POST"],
      uid_field: :email,
      request_path: "/auth/identity",
      callback_path: "/auth/identity/callback",
    ]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
  client_id: System.get_env("FACEBOOK_CLIENT_ID"),
  client_secret: System.get_env("FACEBOOK_CLIENT_SECRET")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
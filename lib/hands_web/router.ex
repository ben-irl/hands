defmodule HandsWeb.Router do
  use HandsWeb, :router

  import HandsWeb.MemberAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HandsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_member
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # scope "/", HandsWeb do
  #   pipe_through :browser
  # end

  # Other scopes may use custom stacks.
  # scope "/api", HandsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:hands, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HandsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", HandsWeb do
    pipe_through [:browser, :redirect_if_member_is_authenticated]

    get "/", PageController, :home

    live_session :redirect_if_member_is_authenticated,
      on_mount: [{HandsWeb.MemberAuth, :redirect_if_member_is_authenticated}] do

      live "/account/register", MemberRegistrationLive, :new
      live "/account/log_in", MemberLoginLive, :new
      live "/account/reset_password", MemberForgotPasswordLive, :new
      live "/account/reset_password/:token", MemberResetPasswordLive, :edit
    end

    post "/account/log_in", MemberSessionController, :create
  end

  scope "/", HandsWeb do
    pipe_through [:browser, :require_authenticated_member]

    live_session :require_authenticated_member,
      on_mount: [{HandsWeb.MemberAuth, :ensure_authenticated}] do

      live "/browse", BrowseLive, :index
      live "/account/profile", MemberProfileLive, :index
      live "/account/settings", MemberSettingsLive, :edit
      live "/account/settings/confirm_email/:token", MemberSettingsLive, :confirm_email
    end
  end

  scope "/", HandsWeb do
    pipe_through [:browser]

    delete "/account/log_out", MemberSessionController, :delete

    live_session :current_member,
      on_mount: [{HandsWeb.MemberAuth, :mount_current_member}] do
      live "/account/confirm/:token", MemberConfirmationLive, :edit
      live "/account/confirm", MemberConfirmationInstructionsLive, :new
    end
  end
end

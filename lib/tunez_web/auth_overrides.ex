defmodule TunezWeb.AuthOverrides do
  use AshAuthentication.Phoenix.Overrides
  alias AshAuthentication.Phoenix.Components

  # configure your UI overrides here

  # First argument to `override` is the component name you are overriding.
  # The body contains any number of configurations you wish to override
  # Below are some examples

  # For a complete reference, see https://hexdocs.pm/ash_authentication_phoenix/ui-overrides.html

  # override AshAuthentication.Phoenix.Components.Banner do
  #   set :image_url, "https://media.giphy.com/media/g7GKcSzwQfugw/giphy.gif"
  #   set :text_class, "bg-red-500"
  # end

  # override AshAuthentication.Phoenix.Components.SignIn do
  #  set :show_banner, false
  # end
  # override Components.Password.Input do
  #   set :submit_class, "bg-primary-600 text-white my-4 py-3 px-5 text-sm rounded-lg"
  # end

  override Components.Banner do
    set :image_url, nil
  end

  override TunezWeb.UiOverrides.RegisterForm do
    set :button_text, "REG"
  end

  override Components.Password do
    set :register_form_module, TunezWeb.UiOverrides.RegisterForm
  end
end

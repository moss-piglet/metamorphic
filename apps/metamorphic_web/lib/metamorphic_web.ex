defmodule MetamorphicWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use MetamorphicWeb, :controller
      use MetamorphicWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: MetamorphicWeb

      import Plug.Conn
      import MetamorphicWeb.Gettext
      alias MetamorphicWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/metamorphic_web/templates",
        namespace: MetamorphicWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MetamorphicWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import MetamorphicWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers
      import MetamorphicWeb.HeexIgnore
      import MetamorphicWeb.LiveHelpers
      import MetamorphicWeb.LiveLetterHelpers
      import MetamorphicWeb.LiveMemoryHelpers
      import MetamorphicWeb.LivePeopleHelpers
      import MetamorphicWeb.LivePortalsHelpers
      import MetamorphicWeb.LiveRelationshipHelpers
      import MetamorphicWeb.LiveSubscriptionHelpers
      import MetamorphicWeb.LiveUtilsEncryptedHelpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import MetamorphicWeb.ErrorHelpers
      import MetamorphicWeb.Gettext

      alias MetamorphicWeb.Router.Helpers, as: Routes
      alias Phoenix.LiveView.JS

      # Shared components (layouts, etc)
      use PetalComponents

      import MetamorphicWeb.Components.{
        AuthLayout,
        Navbar,
        PublicLayout,
        SidebarLayout,
        StackedLayout,
        Layout,
        Brand,
        AuthProviders,
        ColorSchemeSwitch,
        CopyrightComponent,
        LanguageSelect,
        Notification,
        PageComponents,
        PersonDropdownMenu,
        SocialButton,
        LandingPage,
        Subscription
      }

      # Custom helpers
      import MetamorphicWeb.Helpers
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

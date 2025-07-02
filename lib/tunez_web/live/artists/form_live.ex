defmodule TunezWeb.Artists.FormLive do
  use TunezWeb, :live_view
  require Logger

  def mount(%{"id" => artist_id}, _uri, socket) do
    artist = Tunez.Music.get_artist_by_id!(artist_id, actor: socket.assigns.current_user)

    # form =
    #   artist
    #   |> Tunez.Music.form_to_update_artist(actor: socket.assigns.current_user)
    #   |> AshPhoenix.Form.ensure_can_submit!()

    # socket =
    #   socket
    #   |> assign(:form, to_form(form))
    #   |> assign(:page_title, "Edit #{artist.name}")

    socket =
      artist
      |> Tunez.Music.form_to_update_artist(actor: socket.assigns.current_user)
      |> AshPhoenix.Form.can_submit?()
      |> case do
        true ->
          form =
            artist
            |> Tunez.Music.form_to_update_artist(actor: socket.assigns.current_user)
            |> AshPhoenix.Form.ensure_can_submit!()

          socket
          |> assign(:form, to_form(form))
          |> assign(:page_title, "Edit #{artist.name}")

        false ->
          socket
          |> put_flash(:error, "Error accessing page")
          |> redirect(to: ~p"/")
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    form =
      Tunez.Music.form_to_create_artist(actor: socket.assigns.current_user)
      |> AshPhoenix.Form.ensure_can_submit!()

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:page_title, "New Artist")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <.header>
        <.h1>{@page_title}</.h1>
      </.header>

      <.simple_form
        :let={form}
        id="artist_form"
        as={:form}
        for={@form}
        phx-change="validate"
        phx-submit="save"
      >
        <.input phx-debounce="500" field={form[:name]} label="Name" />
        <%= if form[:previous_names].value do %>
          <%= for previous_name <- form[:previous_names].value do %>
            <span class="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-gray-500/10 ring-inset">
              {previous_name}
            </span>
          <% end %>
        <% end %>
        <.input phx-debounce="500" field={form[:biography]} type="textarea" label="Biography" />
        <:actions>
          <.button type="primary">Save</.button>
        </:actions>
      </.simple_form>
    </Layouts.app>
    """
  end

  def handle_event("validate", %{"form" => form_data}, socket) do
    socket =
      socket
      |> update(:form, fn form ->
        AshPhoenix.Form.validate(form, form_data)
      end)

    {:noreply, socket}
  end

  def handle_event("save", %{"form" => form_data}, socket) do
    socket =
      case AshPhoenix.Form.submit(socket.assigns.form, params: form_data) do
        {:ok, artist} ->
          socket
          |> put_flash(:info, "Artist saved successfully")
          |> push_navigate(to: ~p"/artists/#{artist}")

        {:error, form} ->
          socket
          |> put_flash(:error, "Could not save artist")
          |> assign(:form, form)
      end

    {:noreply, socket}
  end
end

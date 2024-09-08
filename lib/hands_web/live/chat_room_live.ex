defmodule HandsWeb.ChatRoomLive do
  use HandsWeb, :live_view
  alias HandsWeb.ChatRoomForm
  alias Hands.Shared.Topics
  alias Hands.Accounts
  alias Hands.Chat.RoomServer
  alias Hands.Chat.Events

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="app-chat-members m-auto flex items-center">
        <div class="py-2 px-4 rounded-full bg-green-100">
          <.icon name="hero-user-solid" class="m-auto text-zinc-600 w-8 h-8" />
          <div class="inline-block"><%= @member_1_profile.name %></div>
        </div>
        <div
          id="app-room-countdown"
          class="px-4"
          phx-update="ignore"
          phx-hook="Countdown"
          data-startsecs={@rem_seconds}
        >
        </div>
        <div class="py-2 px-4 rounded-full bg-orange-100">
          <.icon name="hero-user-solid" class="m-auto text-zinc-600 w-8 h-8" />
          <div class="inline-block"><%= @member_2_profile.name %></div>
        </div>
      </div>

      <.simple_form for={@form} phx-submit="send" class="m-0 p-0">
        <div
          class="w-full fixed left-0 bottom-0 right-0 flex items-center m-0 p-4 border-t border-zinc-300"
          style="margin: 0;"
        >
          <span class="flex-auto mr-2">
            <.input
              type="text"
              field={@form[:message]}
              placeholder="Type your message here..."
              class="!rounded-r-none"
              style="margin-top: 0px;"
            />
          </span>
          <.button class="flex-none !bg-green-600 p-4 text-xl text-white">
            Send
          </.button>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(%{"room_id" => room_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Hands.PubSub, Topics.room_topic(room_id))
    end

    changeset = ChatRoomForm.changeset(%{})
    rem_seconds = RoomServer.fetch_rem_seconds!(room_id)
    [member_1_id, member_2_id] = RoomServer.fetch_member_ids!(room_id)

    member_1_profile = Accounts.fetch_member_profile_by_member_id!(member_1_id)
    member_2_profile = Accounts.fetch_member_profile_by_member_id!(member_2_id)

    {:ok,
      socket
      |> assign(:room_id, room_id)
      |> assign(:member_1_profile, member_1_profile)
      |> assign(:member_2_profile, member_2_profile)
      |> assign(:rem_seconds, rem_seconds)
      |> assign(:form, to_form(changeset))}
  end

  # TODO: State machine to prevent actions until room server is reachable via RoomRegistry

  @impl true
  def handle_event("send", %{"chat_room_form" => form_params}, socket) do
    %{room_id: room_id, current_member: %{id: member_id}} = socket.assigns

    case ChatRoomForm.changeset(form_params) do
      %{valid?: true} ->
        # TODO: Fix this inefficient code.
        %{message: message} = ChatRoomForm.new!(form_params)
        :ok = RoomServer.send_message(room_id, member_id, message)

        changeset = ChatRoomForm.changeset(%{})

        {:noreply, assign(socket, :form, to_form(changeset))}

      %{valid?: false} = changeset ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_info(%Events.RoomOpened{} = _event, socket) do
    # TODO: Convert to UI block and insert into stream
    {:noreply, socket}
  end

  def handle_info(%Events.RoomClosed{} = _event, socket) do
    # TODO: Redirect to feedback form + meetup organization form
    {:noreply,
      socket
      |> put_flash(:error, "Your chat ended.")
      |> redirect(to: ~p"/browse")}
  end

  def handle_info(%Events.MemberJoined{} = _event, socket) do
    # TODO: Convert to UI block and insert into stream
    {:noreply, socket}
  end

  def handle_info(%Events.MemberLeft{} = _event, socket) do
    # TODO: Convert to UI block and insert into stream
    {:noreply, socket}
  end

  def handle_info(%Events.MemberQuit{} = _event, socket) do
    # TODO: Redirect to feedback form + meetup organization form
    {:noreply,
      socket
      |> put_flash(:error, "Your chat ended.")
      |> redirect(to: ~p"/browse")}
  end

  def handle_info(%Events.MessageSent{} = _event, socket) do
    # TODO: Convert to UI block and insert into stream
    {:noreply, socket}
  end

  def handle_info(%Events.MessageSeen{} = _event, socket) do
    # TODO: Convert to UI block and insert into stream
    {:noreply, socket}
  end

  def handle_info(_other_events, socket) do
    {:noreply, socket}
  end
end

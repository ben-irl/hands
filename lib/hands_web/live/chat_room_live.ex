defmodule HandsWeb.ChatRoomLive do
  use HandsWeb, :live_view
  alias HandsWeb.ChatRoomForm
  alias HandsWeb.ChatRoomMessage
  alias Hands.Shared.Topics
  alias Hands.Accounts
  alias Hands.Chat.RoomServer
  alias Hands.Chat.Events

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="app-chat-members m-auto flex items-center border-b border-zinc-300 pb-4">
        <div class="py-2 px-4 rounded-full bg-green-100">
          <.icon name="hero-user-solid" class="m-auto text-zinc-600 w-8 h-8" />
          <div class="inline-block"><%= @member_profiles[@member_1_id].name %></div>
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
          <div class="inline-block"><%= @member_profiles[@member_2_id].name %></div>
        </div>
      </div>

      <main
        id="app-chat-messages"
        phx-update="stream"
      >
        <div id={dom_id} :for={{dom_id, message} <- @streams.messages}>
          <p class={member_msg_class(@member_1_id, @member_2_id, message.member_id)}><%= message.message %></p>
          <p class={member_align_class(@member_1_id, @member_2_id, message.member_id)}>
            <span class={member_bg_class(@member_1_id, @member_2_id, message.member_id)}>
              <%= @member_profiles[message.member_id].name %>
            </span>
          </p>
        </div>
      </main>

      <.simple_form for={@form} phx-submit="send" class="m-0 p-0 bg-white">
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

  # Last minute hack.
  defp member_msg_class(match_1_id, _, match_1_id), do: "px-4 py-2 text-left"
  defp member_msg_class(_, match_2_id, match_2_id), do: "px-4 py-2 text-right"


  defp member_align_class(match_1_id, _, match_1_id), do: ""
  defp member_align_class(_, match_2_id, match_2_id), do: "text-right"

  defp member_bg_class(match_1_id, _, match_1_id), do: "px-4 py-2 rounded-full bg-green-100"
  defp member_bg_class(_, match_2_id, match_2_id), do: "px-4 py-2 rounded-full bg-orange-100"

  @impl true
  def mount(%{"room_id" => room_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Hands.PubSub, Topics.room_topic(room_id))
    end

    changeset = ChatRoomForm.changeset(%{})
    rem_seconds = RoomServer.fetch_rem_seconds!(room_id)
    [member_1_id, member_2_id] = RoomServer.fetch_member_ids!(room_id)
    member_profiles = %{
      member_1_id => Accounts.fetch_member_profile_by_member_id!(member_1_id),
      member_2_id => Accounts.fetch_member_profile_by_member_id!(member_2_id)
    }
    {:ok,
      socket
      |> assign(:room_id, room_id)
      |> assign(:member_profiles, member_profiles)
      |> assign(:member_1_id, member_1_id)
      |> assign(:member_2_id, member_2_id)
      |> assign(:rem_seconds, rem_seconds)
      |> assign(:form, to_form(changeset))
      |> stream_configure(:messages, dom_id: &("message-#{&1.id}"))
      # TODO: Get messages or events from RoomServer memory
      |> stream(:messages, [])}
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

  def handle_info(%Events.MemberJoined{} = event, socket) do
    # TODO: Convert to UI block and insert into stream
    %{member_id: member_id} = event

    message = ChatRoomMessage.new!(member_id, "Joined the chat")

    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info(%Events.MemberLeft{} = event, socket) do
    %{member_id: member_id} = event

    message = ChatRoomMessage.new!(member_id, "Left the chat")

    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info(%Events.MemberQuit{} = _event, socket) do
    # TODO: Redirect to feedback form + meetup organization form
    {:noreply,
      socket
      |> put_flash(:error, "Your chat ended.")
      |> redirect(to: ~p"/browse")}
  end

  def handle_info(%Events.MessageSent{} = event, socket) do
    # TODO: Convert to UI block and insert into stream
    %{member_id: member_id, message: message} = event

    message = ChatRoomMessage.new!(member_id, message)

    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info(%Events.MessageSeen{} = _event, socket) do
    # TODO: Convert to UI block and insert into stream
    {:noreply, socket}
  end

  def handle_info(_other_events, socket) do
    {:noreply, socket}
  end
end

defmodule HandsWeb.BrowseLive do
  use HandsWeb, :live_view
  alias HandsWeb.BrowseForm
  alias Hands.Browse
  alias Hands.Query

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">

      <div class="h-96 rounded-lg bg-zinc-100 flex items-center">
        <.icon name="hero-user-solid" class="m-auto text-zinc-600 w-60 h-60" />
      </div>

      <div class="p-4">
        <b><%= @profile.name %></b>, <%= @profile.age %>
        <p class="overflow-hidden overflow-ellipsis"><%= @tmp_random_description %></p>
      </div>

      <div class="p-4 -mt-10 flex gap-10">
        <.simple_form for={@form} phx-submit="react" class="m-0 p-0">
          <input type="hidden" name={@form[:reaction].name} value="pass"/>
          <input type="hidden" name={@form[:member_id].name} value={@form[:member_id].value} />
          <.button class="!bg-red-600 p-4 text-xl text-white">Pass</.button>
        </.simple_form>

        <.simple_form for={@form} phx-submit="react" class="m-0 p-0">
          <input type="hidden" name={@form[:reaction].name} value="like"/>
          <input type="hidden" name={@form[:member_id].name} value={@form[:member_id].value} />
          <.button class="!bg-green-600 p-4 text-xl text-white">Like</.button>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign_form(socket)}
  end

  def handle_event("react", %{"browse_form" => form_params}, socket) do
    %{id: member_id} = socket.assigns.current_member
    %{reaction: reaction, member_id: seen_member_id} = BrowseForm.new!(form_params)

    case reaction do
      :pass ->
        Browse.create_seen_event!(member_id, seen_member_id)

      :like ->
        Browse.create_seen_event!(member_id, seen_member_id)
        Browse.create_liked_event!(member_id, seen_member_id)
    end

    {:noreply, assign_form(socket)}
  end

  defp assign_form(socket) do
    %{profile: %{is_ready: member_ready?}} = socket.assigns.current_member

    if member_ready? do
      case Query.fetch_next_unseen_profile(socket.assigns.current_member.id) do
        {:ok, profile} ->
          changeset = BrowseForm.changeset(%{member_id: profile.member_id})

          socket
          |> assign(:tmp_random_description, random_description())
          |> assign(:profile, profile)
          |> assign(:form, to_form(changeset))

        {:error, :no_unseen_profiles} ->
          socket
          |> put_flash(:info, "No more unseen profiles!")
          |> redirect(to: ~p"/account/profile")
      end

    else
      socket
      |> put_flash(:info, "Please fill in your profile")
      |> redirect(to: ~p"/account/profile")
    end
  end

  defp random_description() do
    [
      "Donec at libero imperdiet lacus semper euismod. Etiam aliquet fermentum justo vitae tincidunt. Nunc aliquet, ",
      "Felis id pretium scelerisque, turpis nisi imperdiet urna, vitae pulvinar metus quam a elit. In egestas in urna",
      "Eget viverra. Phasellus ullamcorper volutpat tristique. Integer venenatis mi ut velit imperdiet aliquam.",
      "Nunc ut enim tincidunt lacus pretium varius. Curabitur iaculis, tortor nec malesuada hendrerit, magna sem blandit",
      "Sapien, pharetra pulvinar risus justo nec lacus. Proin varius nibh ante, vel porttitor lacus volutpat eget. ",
      "Vestibulum tempus orci mi, pretium laoreet dolor faucibus quis.",
      "Nullam ut nibh non est ultricies mollis a at magna. Sed eu iaculis urna. Pellentesque finibus sodales mauris.",
    ]
    |> Enum.random()
  end
end

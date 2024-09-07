defmodule HandsWeb.MemberProfileLive.Show do
  use HandsWeb, :live_view

  alias Hands.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:member_profile, Accounts.get_member_profile!(id))}
  end

  defp page_title(:show), do: "Show Member profile"
  defp page_title(:edit), do: "Edit Member profile"
end

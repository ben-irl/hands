defmodule HandsWeb.MemberProfileLive.Index do
  use HandsWeb, :live_view

  alias Hands.Accounts
  alias Hands.Accounts.MemberProfile

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :member_profiles, Accounts.list_member_profiles())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Member profile")
    |> assign(:member_profile, Accounts.get_member_profile!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Member profile")
    |> assign(:member_profile, %MemberProfile{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Member profiles")
    |> assign(:member_profile, nil)
  end

  @impl true
  def handle_info({HandsWeb.MemberProfileLive.FormComponent, {:saved, member_profile}}, socket) do
    {:noreply, stream_insert(socket, :member_profiles, member_profile)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    member_profile = Accounts.get_member_profile!(id)
    {:ok, _} = Accounts.delete_member_profile(member_profile)

    {:noreply, stream_delete(socket, :member_profiles, member_profile)}
  end
end

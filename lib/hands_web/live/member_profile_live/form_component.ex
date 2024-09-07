defmodule HandsWeb.MemberProfileLive.FormComponent do
  use HandsWeb, :live_component

  alias Hands.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage member_profile records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="member_profile-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:age]} type="number" label="Age" />
        <.input field={@form[:gender]} type="text" label="Gender" />
        <.input field={@form[:want_genders]} type="text" label="Want genders" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Member profile</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{member_profile: member_profile} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Accounts.change_member_profile(member_profile))
     end)}
  end

  @impl true
  def handle_event("validate", %{"member_profile" => member_profile_params}, socket) do
    changeset = Accounts.change_member_profile(socket.assigns.member_profile, member_profile_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"member_profile" => member_profile_params}, socket) do
    save_member_profile(socket, socket.assigns.action, member_profile_params)
  end

  defp save_member_profile(socket, :edit, member_profile_params) do
    case Accounts.update_member_profile(socket.assigns.member_profile, member_profile_params) do
      {:ok, member_profile} ->
        notify_parent({:saved, member_profile})

        {:noreply,
         socket
         |> put_flash(:info, "Member profile updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_member_profile(socket, :new, member_profile_params) do
    case Accounts.create_member_profile(member_profile_params) do
      {:ok, member_profile} ->
        notify_parent({:saved, member_profile})

        {:noreply,
         socket
         |> put_flash(:info, "Member profile created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

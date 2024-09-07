defmodule HandsWeb.MemberProfileLive do
  use HandsWeb, :live_view
  alias Hands.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Your Profile
      </.header>

      <.simple_form
        for={@form}
        id="member_profile_form"
        phx-submit="save"
        phx-change="validate"
        action={~p"/browse"}
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>


        <.input field={@form[:name]} type="text" label="Name" />

        <label class="block text-sm font-semibold text-zinc-800">I am a...</label>
        <div class="flex items-center m-0 p-0" style="margin: 0;padding:0">
          <.input
            field={@form[:age]}
            type="number"
          />
          <span class="w-20 px-4">yr old</span>
          <.input
            field={@form[:gender]}
            type="select"
            options={["Please select": nil, "Woman": "woman", "Man": "man", "Non-binary": "non_binary"]}
          />
        </div>

        <.input
          field={@form[:want_genders]}
          type="select"
          label="Looking to meet..."
          options={["Woman": "woman", "Man": "man", "Non-binary": "non_binary"]}
          multiple
        />

        <label class="block text-sm font-semibold text-zinc-800">Between the ages of...</label>
        <div class="flex items-center m-0 p-0" style="margin: 0;padding:0">
          <.input field={@form[:want_age_start]} type="number" placeholder="19" class="w-56" />
          <span class="px-4">and</span>
          <.input field={@form[:want_age_end]} type="number" placeholder="120" class="w-56"  />
        </div>

        <:actions>
          <.button phx-disable-with="Updating your profile..." class="w-full">Update your profile</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    %{assigns: %{current_member: current_member}} = socket

    changeset =
      current_member
      |> Accounts.get_member_profile_by_member!()
      |> Accounts.change_member_profile()

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"member_profile" => member_profile_params}, socket) do
    %{assigns: %{current_member: current_member}} = socket

    result =
      current_member
      |> Accounts.get_member_profile_by_member!()
      |> Accounts.update_member_profile(member_profile_params)

    case result do
      {:ok, _} ->
        {:noreply, redirect(socket, to: ~p"/browse")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"member_profile" => member_profile_params}, socket) do
    %{assigns: %{current_member: current_member}} = socket

    changeset =
      current_member
      |> Accounts.get_member_profile_by_member!()
      |> Accounts.change_member_profile(member_profile_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "member_profile")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end

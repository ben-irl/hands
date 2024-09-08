defmodule HandsWeb.ChatFeedbackLive do
  use HandsWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.label>Do you want to meet this person?</.label>

    <div class="p-4 -mt-10 flex gap-10">

      <.button class="!bg-zinc-600 p-4 text-xl text-white">No</.button>
      <.button class="!bg-green-600 p-4 text-xl text-white">Yes</.button>

    </div>

    <.label>How do you feel about the chat?</.label>

    <div class="p-4 -mt-10 flex gap-10">
      <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-4 sm:grid-cols-3">
        <div class="group relative rounded-2xl px-6 py-4 text-sm font-semibold leading-6 text-zinc-900 sm:py-6">
          <span class="absolute inset-0 rounded-2xl bg-green-50 transition group-hover:bg-green-100 sm:group-hover:scale-105">
          </span>
          <span class="relative flex items-center gap-4 sm:flex-col">
            <.icon name="hero-face-smile" class="h-6 w-6" /> Good
          </span>
        </div>
        <div class="group relative rounded-2xl px-6 py-4 text-sm font-semibold leading-6 text-zinc-900 sm:py-6">
          <span class="absolute inset-0 rounded-2xl bg-zinc-50 transition group-hover:bg-zinc-100 sm:group-hover:scale-105">
          </span>
          <span class="relative flex items-center gap-4 sm:flex-col">
            <.icon name="hero-face-frown" class="h-6 w-6" /> Neutral
          </span>
        </div>
        <div class="group relative rounded-2xl px-6 py-4 text-sm font-semibold leading-6 text-zinc-900 sm:py-6">
          <span class="absolute inset-0 rounded-2xl bg-red-50 transition group-hover:bg-red-100 sm:group-hover:scale-105">
          </span>
          <span class="relative flex items-center gap-4 sm:flex-col">
            <.icon name="hero-face-frown" class="h-6 w-6" /> Bad
          </span>
        </div>
      </div>
    </div>


    <.label>Please tag attributes of other person...</.label>

    <div class="p-4">
      <span class="mr-1 px-1 py-0.5 rounded bg-zinc-100">attribute</span>
      <span class="mr-1 px-1 py-0.5 rounded bg-zinc-100">attribute</span>
      <span class="mr-1 px-1 py-0.5 rounded bg-zinc-100">attribute</span>
      <span class="mr-1 px-1 py-0.5 rounded bg-zinc-100">attribute</span>
      <span class="mr-1 px-1 py-0.5 rounded bg-zinc-100">attribute</span>
      <span class="mr-1 px-1 py-0.5 rounded bg-zinc-100">attribute</span>
      <span class="mr-1 px-1 py-0.5 rounded bg-zinc-100">attribute</span>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

defmodule HandsWeb.BrowseLive do
  use HandsWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">

    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

defmodule SearchWeb.PageLive do
  use SearchWeb, :live_view

  alias Search.Repo

  @impl true
  def mount(_, _, socket) do
    model = Replicate.Models.get!("meta/llama-2-7b-chat")
    version = Replicate.Models.get_latest_version!(model)
    user = Search.User |> Repo.get_by!(name: "toran billups")
    thread = Search.Thread |> Repo.get_by!(title: "apple")
    messages = Search.Message |> Repo.all()

    socket = socket |> assign(thread: thread, messages: messages, user: user, version: version, result: nil, text: nil, loading: false, selected: nil, transformer: nil, llama: nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("change_text", %{"message" => text}, socket) do
    socket = socket |> assign(text: text)

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_message", %{"message" => text}, socket) do
    user_id = socket.assigns.user.id
    version = socket.assigns.version
    thread = socket.assigns.thread

    %Search.Message{}
    |> Search.Message.changeset(%{text: text, thread_id: thread.id, user_id: user_id})
    |> Repo.insert!()

    llama =
      Task.async(fn ->
        {:ok, prediction} = Replicate.Predictions.create(version, %{prompt: text})
        Replicate.Predictions.wait(prediction)
      end)

    messages = Search.Message |> Repo.all()

    socket = socket |> assign(messages: messages, llama: llama, text: nil, loading: true)

    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, {:ok, prediction}}, socket) when socket.assigns.llama.ref == ref do
    thread = socket.assigns.thread
    result = Enum.join(prediction.output)
    apple = Search.User |> Repo.get_by!(name: "apple rep")

    %Search.Message{}
    |> Search.Message.changeset(%{text: result, thread_id: thread.id, user_id: apple.id})
    |> Repo.insert!()

    messages = Search.Message |> Repo.all()

    {:noreply, assign(socket, messages: messages, llama: nil, loading: false)}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col grow px-2 sm:px-4 lg:px-8 py-10">
      <div class="flex flex-col grow relative -mb-8 mt-2 mt-2">
        <div class="absolute inset-0 gap-4">
          <div class="h-full flex flex-col bg-white shadow-sm border rounded-md">
            <div class="grid-cols-4 h-full grid divide-x">
              <div class="block relative col-span-4">
                <div class="flex absolute inset-0 flex-col">
                  <div class="relative flex grow overflow-y-hidden">
                    <div class="pt-4 pb-1 px-4 flex flex-col grow overflow-y-auto">
                      <%= for message <- @messages do %>
                      <div :if={message.user_id != 1} class="my-2 flex flex-row justify-start space-x-1 self-start items-start">
                        <div class="flex flex-col space-y-0.5 self-start items-start">
                          <div class="bg-gray-200 text-gray-900 ml-0 mr-12 py-2 px-3 inline-flex text-sm rounded-lg whitespace-pre-wrap"><%= message.text %></div>
                          <div class="mx-1 text-xs text-gray-500"><%= Calendar.strftime(message.inserted_at, "%B %d, %-I:%M %p") %></div>
                        </div>
                      </div>
                      <div :if={message.user_id == 1} class="my-2 flex flex-row justify-start space-x-1 self-end items-end">
                        <div class="flex flex-col space-y-0.5 self-end items-end">
                          <div class="bg-purple-600 text-gray-50 ml-12 mr-0 py-2 px-3 inline-flex text-sm rounded-lg whitespace-pre-wrap"><%= message.text %></div>
                          <div class="mx-1 text-xs text-gray-500"><%= Calendar.strftime(message.inserted_at, "%B %d, %-I:%M %p") %></div>
                        </div>
                      </div>
                      <% end %>
                      <div :if={@loading} class="typing"><div class="typing__dot"></div><div class="typing__dot"></div><div class="typing__dot"></div></div>
                    </div>
                  </div>
                  <form class="px-4 py-2 flex flex-row items-end gap-x-2" phx-submit="add_message" phx-change="change_text">
                    <div class="flex flex-col grow rounded-md border border-gray-300">
                      <div class="relative flex grow">
                        <input id="message" name="message" value={@text} class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm placeholder:text-gray-400 text-gray-900" placeholder="Aa" type="text" />
                      </div>
                    </div>
                    <div class="ml-1">
                      <button type="submit" class="flex items-center justify-center h-10 w-10 rounded-full bg-gray-200 hover:bg-gray-300 text-gray-500">
                        <svg class="w-5 h-5 transform rotate-90 -mr-px" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
                        </svg>
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

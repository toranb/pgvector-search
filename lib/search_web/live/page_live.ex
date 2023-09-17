defmodule SearchWeb.PageLive do
  use SearchWeb, :live_view

  alias Search.Repo

  @impl true
  def mount(_, _, socket) do
    model = Replicate.Models.get!("meta/llama-2-7b-chat")
    version = Replicate.Models.get_latest_version!(model)
    user = Search.User |> Repo.get_by!(name: "toran billups")
    threads = Search.Thread |> Repo.all() |> Repo.preload(messages: :user)

    socket = socket |> assign(version: version, user: user, threads: threads, result: nil, text: nil, loading: false, selected: nil, query: nil, transformer: nil, llama: nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_thread", %{"id" => thread_id}, socket) do
    thread = socket.assigns.threads |> Enum.find(& &1.id == String.to_integer(thread_id))
    socket = socket |> assign(selected: thread)

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_text", %{"message" => text}, socket) do
    socket = socket |> assign(text: text)

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_message", %{"message" => text}, socket) do
    user_id = socket.assigns.user.id
    selected_id = socket.assigns.selected.id

    message =
      %Search.Message{}
      |> Search.Message.changeset(%{text: text, thread_id: selected_id, user_id: user_id})
      |> Repo.insert!()

    transformer =
      Task.async(fn ->
        {message.id, Nx.Serving.batched_run(SentenceTransformer, text)}
      end)

    threads = Search.Thread |> Repo.all() |> Repo.preload(messages: :user)
    selected = threads |> Enum.find(& &1.id == selected_id)
    socket = socket |> assign(threads: threads, selected: selected, transformer: transformer, text: nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("query", %{"search" => value}, %{assigns: %{loading: true}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("query", %{"search" => value}, %{assigns: %{loading: false}} = socket) do
    query =
      Task.async(fn ->
        {value, Nx.Serving.batched_run(SentenceTransformer, value)}
      end)

    socket = socket |> assign(query: query, loading: true)

    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, {message_id, %{embedding: embedding}}}, socket) when socket.assigns.transformer.ref == ref do
    Search.Message
    |> Repo.get!(message_id)
    |> Search.Message.changeset(%{embedding: embedding})
    |> Repo.update!()

    socket = socket |> assign(transformer: nil)

    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, {question, %{embedding: embedding}}}, socket) when socket.assigns.query.ref == ref do
    %Search.Message{thread_id: thread_id} = Search.Message.search(embedding)

    thread = socket.assigns.threads |> Enum.find(& &1.id == thread_id)
    prompt = Search.Replicate.generate_prompt(question, thread)
    version = socket.assigns.version

    llama =
      Task.async(fn ->
        {:ok, prediction} = Replicate.Predictions.create(version, %{prompt: prompt})
        {thread.id, Replicate.Predictions.wait(prediction)}
      end)

    {:noreply, assign(socket, query: nil, llama: llama, selected: thread)}
  end

  @impl true
  def handle_info({ref, {thread_id, {:ok, prediction}}}, socket) when socket.assigns.llama.ref == ref do
    result = Enum.join(prediction.output)
    thread = socket.assigns.threads |> Enum.find(& &1.id == thread_id)

    {:noreply, assign(socket, llama: nil, result: result, selected: thread, loading: false)}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col grow px-2 sm:px-4 lg:px-8 py-10">
      <form class="mt-4" phx-submit="query">
        <label class="relative flex items-center">
          <input id="search" name="search" type="search" placeholder="ask a question ..." class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm placeholder:text-gray-400 text-gray-900 pl-8" autofocus>
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true" class="absolute left-2 h-5 text-gray-500">
            <path fill-rule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clip-rule="evenodd"></path>
          </svg>
        </label>
      </form>
      <div class="flex flex-col grow relative -mb-8 mt-2 mt-2">
        <div class="absolute inset-0 gap-4">
          <div class="h-full flex flex-col bg-white shadow-sm border rounded-md">
            <div class="grid-cols-4 h-full grid divide-x">
              <div class="flex flex-col hover:scroll-auto">
                <div class="flex flex-col justify-stretch grow p-2">
                  <%= for thread <- @threads do %>
                  <div id={"thread-#{thread.id}"} class="flex flex-col justify-stretch">
                    <button type="button" phx-click="select_thread" phx-value-id={thread.id} class={"flex p-4 items-center justify-between rounded-md hover:bg-gray-100 text-sm text-left text-gray-700 outline-none #{if @selected && @selected.id == thread.id, do: "bg-gray-100"}"}>
                      <div class="flex flex-col overflow-hidden">
                        <div class="inline-flex items-center space-x-1 font-medium text-sm text-gray-800">
                          <div class="p-1 rounded-full bg-gray-200 text-gray-900">
                            <div class="rounded-full w-9 h-9 min-w-9 flex justify-center items-center text-base bg-purple-600 text-white capitalize"><%= String.first(thread.title) %></div>
                          </div>
                          <span class="pl-1 capitalize"><%= thread.title %></span>
                        </div>
                        <div class="hidden mt-1 inline-flex justify-start items-center flex-nowrap text-xs text-gray-500 overflow-hidden">
                          <span class="whitespace-nowrap text-ellipsis overflow-hidden"><%= thread.title %></span>
                          <span class="mx-1 inline-flex rounded-full w-0.5 h-0.5 min-w-0.5 bg-gray-500"></span>
                        </div>
                      </div>
                    </button>
                  </div>
                  <% end %>
                </div>
              </div>
              <div class={"block relative #{if @loading || !is_nil(@result), do: "col-span-2", else: "col-span-3"}"}>
                <div class="flex absolute inset-0 flex-col">
                  <div class="relative flex grow overflow-y-hidden">
                    <div :if={!is_nil(@selected)} class="pt-4 pb-1 px-4 flex flex-col grow overflow-y-auto">
                      <%= for message <- @selected.messages do %>
                      <div :if={message.user_id != @user.id} id={"message-#{message.id}"} class="my-2 flex flex-row justify-start space-x-1 self-start items-start">
                        <div class="rounded-full w-9 h-9 min-w-9 flex justify-center items-center text-base bg-gray-100 text-gray-900 capitalize"><%= String.first(message.user.name) %></div>
                        <div class="flex flex-col space-y-0.5 self-start items-start">
                          <div class="bg-gray-200 text-gray-900 ml-0 mr-12 py-2 px-3 inline-flex text-sm rounded-lg whitespace-pre-wrap"><%= message.text %></div>
                          <div class="mx-1 text-xs text-gray-500"><%= Calendar.strftime(message.inserted_at, "%B %d, %-I:%M %p") %></div>
                        </div>
                      </div>
                      <div :if={message.user_id == @user.id} id={"message-#{message.id}"} class="my-2 flex flex-row justify-start space-x-1 self-end items-end">
                        <div class="flex flex-col space-y-0.5 self-end items-end">
                          <div class="bg-purple-600 text-gray-50 ml-12 mr-0 py-2 px-3 inline-flex text-sm rounded-lg whitespace-pre-wrap"><%= message.text %></div>
                          <div class="mx-1 text-xs text-gray-500"><%= Calendar.strftime(message.inserted_at, "%B %d, %-I:%M %p") %></div>
                        </div>
                      </div>
                      <% end %>
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
              <div :if={!is_nil(@selected) && @loading} class="block col-span-1 relative">
                <div class="flex absolute inset-0 flex-col justify-stretch">
                  <.ghost_summary />
                </div>
              </div>
              <div :if={!is_nil(@result)} class="block col-span-1 relative">
                <div class="flex absolute inset-0 flex-col justify-stretch">
                  <div class="p-4 space-y-6 flex flex-col grow overflow-y-auto"><div>
                  <p class="font-medium text-sm text-gray-900">Summary</p>
                  <p class="pt-4 text-sm text-gray-900"><%= @result %></p>
                </div>
              </div>
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

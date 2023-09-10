defmodule SearchWeb.PageLive do
  use SearchWeb, :live_view

  @impl true
  def mount(_, _, socket) do
    socket = socket |> assign(task: nil, transformer: nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("start", _value, socket) do
    text = "the tiny dog"
    # text = "the big human"
    # text = "the little tree"
    # text = "the big truck"
    # text = "the big car"
    # text = "the happy dinosaur"

    transformer =
      Task.async(fn ->
        {text, Nx.Serving.batched_run(SentenceTransformer, text)}
      end)

    socket = socket |> assign(task: nil, transformer: transformer)

    {:noreply, socket}
  end

  @impl true
  def handle_event("query", _value, socket) do
    text = "the huge person"

    query =
      Task.async(fn ->
        Nx.Serving.batched_run(SentenceTransformer, text)
      end)

    socket = socket |> assign(task: nil, query: query)

    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, %{embedding: embedding}}, socket) when socket.assigns.query.ref == ref do
    Search.Item.search(embedding)
    |> IO.inspect(label: "query result")

    {:noreply, assign(socket, query: nil)}
  end

  @impl true
  def handle_info({ref, {text, %{embedding: embedding}}}, socket)
      when socket.assigns.transformer.ref == ref do
    %Search.Item{text: text, embedding: embedding}
    |> Search.Repo.insert!()

    {:noreply, assign(socket, transformer: nil)}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen">
      <div class="flex w-full justify-center items-center">
        <div class="flex justify-center items-center h-20 w-20 rounded-full bg-gray-700 p-2"></div>
      </div>
      <div class="flex h-screen w-full justify-center items-center">
        <div id="mic-element" class="flex h-20 w-20 rounded-full bg-gray-700 p-2" phx-hook="Demo">
          <div
            :if={@task}
            class="h-full w-full bg-white rounded-full ring-2 ring-white animate-spin border-4 border-solid border-blue-500 border-t-transparent"
          >
          </div>
          <button
            :if={!@task}
            class="h-full w-full bg-red-500 rounded-full ring-2 ring-white"
            type="button"
            phx-click="start"
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
          </button>
        </div>
      </div>
    </div>
    """
  end
end

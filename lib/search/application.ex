defmodule Search.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SearchWeb.Telemetry,
      # Chat with llama 2
      {Nx.Serving, serving: llama(), name: ChatServing},
      # Nx for word embeddings
      # {Nx.Serving, serving: serving(), name: SentenceTransformer},
      # Start the Ecto repository
      Search.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Search.PubSub},
      # Start Finch
      {Finch, name: Search.Finch},
      # Start the Endpoint (http/https)
      SearchWeb.Endpoint
      # Start a worker by calling: Search.Worker.start_link(arg)
      # {Search.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Search.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SearchWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def serving() do
    repo = "thenlper/gte-base"
    {:ok, model_info} = Bumblebee.load_model({:hf, repo})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, repo})

    Bumblebee.Text.TextEmbedding.text_embedding(model_info, tokenizer,
      embedding_processor: :l2_norm,
      compile: [batch_size: 32, sequence_length: [32]],
      defn_options: [compiler: EXLA]
    )
  end

  def llama() do
    llama = {:local, "/home/toranb/lit/out/lora_merged/Llama-2-7b-chat-hf"}
    {:ok, spec} = Bumblebee.load_spec(llama, module: Bumblebee.Text.Llama, architecture: :for_causal_language_modeling)

    {:ok, model_info} = Bumblebee.load_model(llama, spec: spec, backend: {EXLA.Backend, client: :host})
    {:ok, tokenizer} = Bumblebee.load_tokenizer(llama, module: Bumblebee.Text.LlamaTokenizer)
    {:ok, generation_config} = Bumblebee.load_generation_config(llama, spec_module: Bumblebee.Text.Llama)

    generation_config = Bumblebee.configure(generation_config, max_new_tokens: 100)
    Bumblebee.Text.generation(model_info, tokenizer, generation_config, defn_options: [compiler: EXLA])
  end
end

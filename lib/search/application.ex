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
      # Nx for mistral 7b
      {Nx.Serving, serving: serving(), name: ChatServing},
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
    # mistral = {:hf, "mistralai/Mistral-7B-Instruct-v0.1"}
    mistral = {:local, "/home/toranb/lit/out/lora_merged/Mistral-7B-v0.1"}
    {:ok, spec} = Bumblebee.load_spec(mistral, module: Bumblebee.Text.Mistral, architecture: :for_causal_language_modeling)

    {:ok, model_info} = Bumblebee.load_model(mistral, spec: spec, backend: {EXLA.Backend, client: :host})
    {:ok, tokenizer} = Bumblebee.load_tokenizer(mistral, module: Bumblebee.Text.LlamaTokenizer)
    {:ok, generation_config} = Bumblebee.load_generation_config(mistral, spec_module: Bumblebee.Text.Mistral)

    generation_config = Bumblebee.configure(generation_config, max_new_tokens: 500)
    Bumblebee.Text.generation(model_info, tokenizer, generation_config, defn_options: [compiler: EXLA])
  end
end

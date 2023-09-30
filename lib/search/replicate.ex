defmodule Search.Replicate do
  def generate_prompt(question, thread) do
    context =
      thread.messages
      |> Enum.reduce("", fn message, acc ->
        if String.length(acc) == 0 do
          message.text
        else
          acc <> ", " <> message.text
        end
      end)

    """
    [INST] <<SYS>>
    You are an assistant for question-answering tasks. Use the following pieces of retrieved context to answer the question.
    If you do not know the answer, just say that you don't know. Use two sentences maximum and keep the answer concise.
    <</SYS>>
    Question: #{question}
    Context: #{context}[/INST]
    """
  end
end

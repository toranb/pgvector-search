toran =
  %Search.User{name: "toran billups"}
  |> Search.Repo.insert!()

apple_rep =
  %Search.User{name: "apple rep"}
  |> Search.Repo.insert!()

spotify_rep =
  %Search.User{name: "spotify rep"}
  |> Search.Repo.insert!()

sprint_rep =
  %Search.User{name: "sprint rep"}
  |> Search.Repo.insert!()

southwest_rep =
  %Search.User{name: "southwest rep"}
  |> Search.Repo.insert!()

######
apple =
  %Search.Thread{title: "apple"}
  |> Search.Repo.insert!()

spotify =
  %Search.Thread{title: "spotify"}
  |> Search.Repo.insert!()

sprint =
  %Search.Thread{title: "sprint"}
  |> Search.Repo.insert!()

southwest =
  %Search.Thread{title: "southwest"}
  |> Search.Repo.insert!()

######
text = "So the new update does not let me listen to music and go on whatsapp at the same time"
%{embedding: embedding} = Nx.Serving.batched_run(SentenceTransformer, text)

apple_one =
  %Search.Message{thread_id: apple.id, user_id: toran.id, text: text, embedding: embedding}
  |> Search.Repo.insert!()

text =
  "Hi Toran! Help is here. Can you check if logging out and restarting your device and logging back in makes a difference?"

%{embedding: embedding} = Nx.Serving.batched_run(SentenceTransformer, text)

apple_two =
  %Search.Message{thread_id: apple.id, user_id: apple_rep.id, text: text, embedding: embedding}
  |> Search.Repo.insert!()

text = "What is the exact iOS you are using? Are you using any specific apps when noticing this?"
%{embedding: embedding} = Nx.Serving.batched_run(SentenceTransformer, text)

apple_three =
  %Search.Message{thread_id: apple.id, user_id: apple_rep.id, text: text, embedding: embedding}
  |> Search.Repo.insert!()

text =
  "I'm on the latest version. I have read the help page turned off virtually all apps and location svs too but in typing this I dropped 3% battery life"

%{embedding: embedding} = Nx.Serving.batched_run(SentenceTransformer, text)

apple_four =
  %Search.Message{thread_id: apple.id, user_id: toran.id, text: text, embedding: embedding}
  |> Search.Repo.insert!()

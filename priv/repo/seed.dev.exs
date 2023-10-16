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

symantec_rep =
  %Search.User{name: "symantec rep"}
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

symantec =
  %Search.Thread{title: "symantec"}
  |> Search.Repo.insert!()

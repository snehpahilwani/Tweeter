  defmodule TwitterSimulatorWeb.ServerChannel do
    use Phoenix.Channel

    def join("server:twtr", _message, socket) do
      {:ok, socket}
    end
    

    def handle_in("signup", %{"userName" => userName, "pass" => pass}, socket) do
      if Server.signup(userName, pass) do
          push socket, "signup_success", %{body: "Welcome to Tweeter!"}
      else
          push socket, "signup_failure", %{body: "User already exists!"}
      end
    {:noreply, socket}
    end  
  


    def handle_in("login", %{"userName" => userName, "pass" => pass}, socket) do
      if Server.login(userName, pass) do
          push socket, "login_success", %{body: "Welcome back to Tweeter!", userName: userName}
          
      else
          push socket, "login_failure", %{body: "Wrong username/password combination"}
      end
    {:noreply, socket}
    end

    def handle_in("tweet", %{"userName" => userName, "tweet"=> tweet}, socket) do
        Server.tweetAPI(:ets.info(:tweets_table)[:size] + 1, userName, tweet, [])
        {:reply, :ok, socket}
    end

    def handle_in("query", %{"userName" => userName, "hashOrMention"=> hashOrMention}, socket) do
        Server.query(userName, hashOrMention)
        {:reply, :ok, socket}
    end

    def handle_in("retweet", %{"userName" => userName, "retweetID" => retweetID}, socket) do
        Server.retweet(userName, retweetID)
        {:reply, :ok, socket}
    end

    def handle_in("follow", %{"userName" => userName, "user_to_follow" => user_to_follow}, socket) do
        Server.follow(user_to_follow, userName)
        {:reply, :ok, socket}
    end

    def handle_in("logout", %{"userName" => userName}, socket) do
        {:reply, :ok, socket}
    end

    def join("server:" <> _private_room_id, _params, _socket) do
      {:error, %{reason: "unauthorized"}}
    end
  end
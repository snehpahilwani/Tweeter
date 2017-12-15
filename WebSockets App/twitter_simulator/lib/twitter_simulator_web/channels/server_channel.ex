  defmodule TwitterSimulatorWeb.ServerChannel do
    use Phoenix.Channel

    def join("server:twtr", _message, socket) do
      {:ok, socket}
    end
    

    def handle_in("signup", %{"userName" => userName, "pass" => pass}, socket) do
      if Server.signup(userName, pass) do
          push socket, "signup_success", %{body: "Welcome to Tweeter! Please login below."}
      else
          push socket, "signup_failure", %{body: "User already exists! Please login or create a new user."}
      end
    {:noreply, socket}
    end  
  

    def handle_in("updateSocket", %{"userName" => userName}, socket) do
      :ets.insert(:sockets, {userName, socket})
      {:noreply, socket}
    end

    def handle_in("updateFeed", %{"userName" => userName}, socket) do
      following_tweetList = Server.feedData(userName)
      

      push socket, "updateFeed", %{queryList: following_tweetList}
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
      tweetID = :ets.info(:tweets_table)[:size] + 1
      follow_plus_mentions = Server.tweetAPI(tweetID, userName, tweet, [])
      tweets = Enum.at(Server.buildList([tweetID], [], 0),0)
      IO.inspect tweets
      payload = %{tweet: tweets}
      send_to_followers(follow_plus_mentions, payload)
      {:noreply, socket}
    end

    def handle_in("query", %{"userName" => userName, "hashOrMention"=> hashOrMention}, socket) do
        queryList = Server.query(userName, hashOrMention)
        IO.puts "Query List in Handle method"
        IO.inspect queryList
        push socket, "queryList", %{queryList: queryList}
        {:noreply, socket}
    end

    def handle_in("retweet", %{"userName" => userName, "retweetID" => retweetID}, socket) do
        tweetID = Server.retweet(userName, retweetID)
        followers_list = Server.get("user_table", userName, 3)
        tweets = Enum.at(Server.buildList([tweetID], [], 0),0)
        payload = %{tweet: tweets}
        send_to_followers(followers_list, payload)
        {:noreply, socket}
    end

    def handle_in("follow", %{"userName" => userName, "user_to_follow" => user_to_follow}, socket) do
        status = Server.follow(user_to_follow, userName)
        push socket, "follow_status", %{status: status}
        {:noreply, socket}
    end

    def handle_in("logout", %{"userName" => userName}, socket) do
        {:noreply, socket}
    end

    def send_to_followers(follow_plus_mentions, tweet) do
      if length(follow_plus_mentions) > 0 do
        user = Enum.at(follow_plus_mentions,0)
        IO.inspect user

        follow_plus_mentions = follow_plus_mentions -- [user]
        socket = Server.get("sockets", user, 1)
        IO.inspect socket
        push socket, "getTweet", tweet 
        send_to_followers(follow_plus_mentions, tweet)
      end
    end

    def join("server:" <> _private_room_id, _params, _socket) do
      {:error, %{reason: "unauthorized"}}
    end
  end
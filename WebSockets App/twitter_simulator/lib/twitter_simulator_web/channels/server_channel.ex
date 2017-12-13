defmodule TwitterSimulatorWeb.ServerChannel do
  use Phoenix.Channel

    def join("server:twtr", _message, socket) do
    {:ok, socket}
  end
  

  def handle_in("signup", %{"userName" => userName, "pass" => pass}, socket) do
   {:reply, :ok, socket}
  end  
 


  def handle_in("login", %{"userName" => userName, "pass" => pass}, socket) do
       {:reply, {:ok, %{"userName" => userName,"pass" => pass}}, socket}
  end

  def handle_in("tweet", %{"userName" => userName, "tweet"=> tweet}, socket) do
       {:reply, :ok, socket}
  end

  def handle_in("retweet", %{"userName" => userName, "retweetID" => retweetID}, socket) do
       {:reply, :ok, socket}
  end

  def handle_in("follow", %{"userName" => userName, "user_to_follow" => user_to_follow}, socket) do
       {:reply, :ok, socket}
  end

  def handle_in("logout", %{"userName" => userName}, socket) do
       {:reply, :ok, socket}
  end

  def join("server:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end
end
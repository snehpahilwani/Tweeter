defmodule TwitterSimulatorWeb.ServerChannel do
  use Phoenix.Channel

  def join("server:twtr", _message, socket) do
    {:ok, socket}
  end
  

  # def handle_in("sign_up", %{"username" => username, "pass" => pass}, socket) do
    
  #   broadcast! socket, "new_msg", %{body: body}
  #   {:noreply, socket}
  # end


  def handle_in("login", %{"username" => username, "pass" => pass}, socket) do
    
  end

  def join("server:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end
end
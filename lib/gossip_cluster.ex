defmodule GossipCluster do
  use GenServer
  require Logger

  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  @impl true
  def init(options) do
    port = Keyword.get(options, :port, 8888)
    mcast_address = Keyword.get(options, :mcast_address, {233, 252, 1, 0})
    mcast_interface = Keyword.get(options, :mcast_interface, {0, 0, 0, 0})
    mcast_ttl = Keyword.get(options, :mcast_ttl, 1)

    {:ok, socket} =
      :gen_udp.open(port, [
        :binary,
        {:add_membership, {mcast_address, mcast_interface}},
        {:multicast_ttl, mcast_ttl}
      ])
    :net_kernel.monitor_nodes(true)
    schedule_heartbeat()

    {:ok, %{socket: socket, destination: {mcast_address, port}}}
  end

  defp schedule_heartbeat() do
    Process.send_after(self(), :send_heartbeat, 1_000)
  end

  # "Gossip" our node name via a multicast heartbeat over the UDP socket
  @impl true
  def handle_info(:send_heartbeat, state) do
    %{socket: socket, destination: destination} = state
    packet = "heartbeat::" <> :erlang.term_to_binary(node())
    :gen_udp.send(socket, destination, packet)
    schedule_heartbeat()
    {:noreply, state}
  end

  # Handle a hearbeat received on the UDP socket
  @impl true
  def handle_info(
        {:udp, _socket, _ip, _port, <<"heartbeat::", data::binary>>},
        state
      ) do
    node = :erlang.binary_to_term(data)
    Logger.debug("Received hearbeat from #{inspect(node)}")
    Node.connect(node)
    {:noreply, state}
  end

  # Handle "Nodeup" messages sent when new node connections are established.
  # See :net_kernel.monitor_nodes/1
  @impl true
  def handle_info({:nodeup, node}, state) do
    Logger.info("NODEUP: Connection to node #{inspect(node)} established")
    {:noreply, state}
  end

  # Handle "Nodedown" messages sent when nodes are disconnected.
  # See :net_kernel.monitor_nodes/1
  @impl true
  def handle_info({:nodedown, node}, state) do
    Logger.info("NODEDOWN: Connection to node #{inspect(node)} terminated")
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    %{socket: socket} = state
    :gen_udp.close(socket)
  end
end

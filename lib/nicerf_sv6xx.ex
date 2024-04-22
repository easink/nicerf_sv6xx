# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule NiceRF_SV6xx do
  @moduledoc """
  Documentation for `NiceRF_SV6xx`.
  """

  defstruct [
    :rf_channel,
    :rf_freq_band,
    :rf_data_rate,
    :rf_output_power,
    :serial_data_rate,
    :serial_data_bit,
    :serial_stop_bit,
    :serial_parity,
    :net_id,
    :node_id
  ]

  @type t :: %NiceRF_SV6xx{}

  alias __MODULE__

  @cmd_get_version <<0xAA, 0xFA, 0xAA>>
  @cmd_get_params <<0xAA, 0xFA, 0x01>>
  @cmd_reset <<0xAA, 0xFA, 0x02>>
  @cmd_set_params <<0xAA, 0xFA, 0x03>>
  @cmd_rssi_index <<0xAA, 0xFA, 0x04>>

  @timeout 1000

  @spec start_link() :: GenServer.on_start()
  def start_link do
    Circuits.UART.start_link()
  end

  @spec enumerate() :: map()
  def enumerate do
    Circuits.UART.enumerate()
  end

  @spec open(pid(), String.t(), list) :: :ok | {:error, File.posix()}
  def open(pid, device, opts \\ []) do
    data_rate = opts[:data_rate] || default_params().serial_data_rate
    Circuits.UART.open(pid, device, speed: data_rate, active: false)
  end

  @spec read(pid(), non_neg_integer()) ::
          {:ok, binary()} | {:ok, {:partial, binary()}} | {:error, File.posix()}
  def read(pid, timeout \\ 1000) do
    Circuits.UART.read(pid, timeout)
  end

  @spec write(pid(), iodata(), non_neg_integer()) :: :ok | {:error, File.posix()}
  def write(pid, data, timeout \\ 1000) do
    Circuits.UART.write(pid, data, timeout)
  end

  @spec version(pid()) :: String.t()
  def version(pid) do
    write(pid, @cmd_get_version)
    {:ok, version} = read(pid, @timeout)
    String.trim(version)
  end

  @spec get_parameters(pid()) :: NiceRF_SV6xx.t()
  def get_parameters(pid) do
    write(pid, @cmd_get_params)
    {:ok, parameters} = read(pid, @timeout)

    <<
      rf_channel,
      rf_freq_band1,
      rf_data_rate,
      rf_output_power,
      serial_data_rate,
      serial_data_bit,
      serial_stop_bit,
      serial_parity,
      net_id::32,
      node_id::16,
      ?\r,
      ?\n
    >> = parameters

    %NiceRF_SV6xx{
      rf_channel: rf_channel,
      rf_freq_band: from_freq_band(rf_freq_band1),
      rf_data_rate: from_data_rate(rf_data_rate),
      rf_output_power: from_rf_output_power(rf_output_power),
      serial_data_rate: from_data_rate(serial_data_rate),
      serial_data_bit: from_serial_data_bit(serial_data_bit),
      serial_stop_bit: from_serial_stop_bit(serial_stop_bit),
      serial_parity: from_serial_parity(serial_parity),
      net_id: net_id,
      node_id: node_id
    }
  end

  @spec reset(pid()) :: :ok | :error
  def reset(pid) do
    write(pid, @cmd_reset)

    case read(pid, @timeout) do
      {:ok, "OK\r\n"} -> :ok
      {:ok, "ERROR\r\n"} -> :error
    end
  end

  @spec set_parameters(pid(), NiceRF_SV6xx.t()) :: :ok | :error
  def set_parameters(pid, params \\ %NiceRF_SV6xx{}) do
    params = Map.merge(default_params(), params)

    data =
      <<
        @cmd_set_params::binary,
        params.rf_channel,
        to_freq_band(params.rf_freq_band),
        to_data_rate(params.rf_data_rate),
        to_rf_output_power(params.rf_output_power),
        to_data_rate(params.serial_data_rate),
        to_serial_data_bit(params.serial_data_bit),
        to_serial_stop_bit(params.serial_stop_bit),
        to_serial_parity(params.serial_parity),
        params.net_id::32,
        params.node_id::16
      >>

    write(pid, data)

    case read(pid, @timeout) do
      {:ok, "OK\r\n"} -> :ok
      {:ok, "ERROR\r\n"} -> :error
    end
  end

  @spec rssi_signal(pid()) :: {non_neg_integer(), non_neg_integer()}
  def rssi_signal(pid) do
    write(pid, @cmd_rssi_index)

    {:ok, <<a, b, ?\r, ?\n>>} = read(pid, @timeout)
    {a, b}
  end

  #
  # Private
  #

  # defp from_channel_433(channel), do:

  @from_freq_band %{1 => 433, 2 => 490, 3 => 868, 4 => 915}
  @to_freq_band Map.new(@from_freq_band, fn {k, v} -> {v, k} end)

  defp from_freq_band(freq_band), do: @from_freq_band[freq_band]
  defp to_freq_band(freq_band), do: @to_freq_band[freq_band]

  @from_data_rate %{
    0 => 1200,
    1 => 2400,
    2 => 4800,
    3 => 9600,
    4 => 14_400,
    5 => 19_200,
    6 => 38_400,
    7 => 57_600,
    8 => 76_800,
    9 => 115_200
  }
  @to_data_rate Map.new(@from_data_rate, fn {k, v} -> {v, k} end)

  defp from_data_rate(data_rate), do: @from_data_rate[data_rate]
  defp to_data_rate(data_rate), do: @to_data_rate[data_rate]

  @from_rf_output_power %{
    0 => {2406, 0},
    1 => {2638, 1},
    2 => {2760, 2},
    3 => {2800, 3},
    4 => {2800, 4},
    5 => {2800, 5},
    6 => {2800, 6},
    7 => {2800, 7}
  }
  @to_rf_output_power Map.new(@from_rf_output_power, fn {k, v} -> {v, k} end)

  defp from_rf_output_power(output_power), do: @from_rf_output_power[output_power]
  defp to_rf_output_power(output_power), do: @to_rf_output_power[output_power]

  @from_serial_data_bit %{
    1 => 7,
    2 => 8,
    3 => 9
  }
  @to_serial_data_bit Map.new(@from_serial_data_bit, fn {k, v} -> {v, k} end)

  defp from_serial_data_bit(data_bit), do: @from_serial_data_bit[data_bit]
  defp to_serial_data_bit(data_bit), do: @to_serial_data_bit[data_bit]

  @from_serial_stop_bit %{
    1 => 1,
    2 => 2
  }
  @to_serial_stop_bit Map.new(@from_serial_stop_bit, fn {k, v} -> {v, k} end)

  defp from_serial_stop_bit(stop_bit), do: @from_serial_stop_bit[stop_bit]
  defp to_serial_stop_bit(stop_bit), do: @to_serial_stop_bit[stop_bit]

  @from_serial_parity %{
    1 => :no,
    2 => :odd,
    3 => :even
  }
  @to_serial_parity Map.new(@from_serial_parity, fn {k, v} -> {v, k} end)

  defp from_serial_parity(parity_bit), do: @from_serial_parity[parity_bit]
  defp to_serial_parity(parity), do: @to_serial_parity[parity]

  @spec default_params() :: NiceRF_SV6xx.t()
  def default_params do
    %NiceRF_SV6xx{
      rf_channel: 20,
      rf_freq_band: 433,
      net_id: 0,
      node_id: 0,
      rf_data_rate: 9600,
      rf_output_power: {2800, 7},
      serial_data_rate: 9600,
      serial_data_bit: 8,
      serial_parity: :no,
      serial_stop_bit: 1
    }
  end
end

library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.STD_LOGIC_UNSIGNED.all;

entity uart is
    port(
        rx: in std_logic;
        D_out: out std_logic_vector(7 downto 0):=x"00";
        data_recieved: out std_logic := '0';
        ready_for_transmit: out std_logic:= '0';
        start_transmit:in std_logic;
        clock: in std_logic;
        D_in: in std_logic_vector(7 downto 0);
        tx: out std_logic:= '1'
    );
    end entity uart;

architecture transciever of uart is

signal bit_index :unsigned (3 downto 0):=x"0";
signal transmit_bit_index :unsigned (3 downto 0):=x"0";
--signal recieve_timer: unsigned (15 downto 0) := "0000";
signal recieved_byte: std_logic_vector( 7 downto 0);
signal transmit_byte: std_logic_vector(7 downto 0):= x"00";

--statemachine states
constant IDLE: unsigned (3 downto 0):= x"0";
constant RECIEVE_BYTE: unsigned ( 3 downto 0):= x"1";
constant SEND_RECIEVED: unsigned(3 downto 0):=x"2";
constant SEND_BYTE: unsigned(3 downto 0):= x"3";

signal recieve_state: unsigned (3 downto 0) := IDLE;
signal transmit_state: unsigned (3 downto 0) := IDLE;

begin

recieve: process(clock)
begin
    --process to recieve date, note: process is dependent on cloksignal that has the same frequency as the baudrate.
    if falling_edge(clock) then
        case recieve_state is
            when IDLE =>
                recieved_byte <= x"00";
                bit_index <= x"0";
                data_recieved <= '0';
                if rx = '0' then --start condition detected;
                    recieve_state <= RECIEVE_BYTE;
                end if;
            when RECIEVE_BYTE => --recieve byte
                if bit_index /= x"8" then
                    recieved_byte(to_integer(bit_index)) <= rx;
                    bit_index <= bit_index +1;
                else
                recieve_state <= SEND_RECIEVED;
                end if;
            when SEND_RECIEVED =>
                D_out <= recieved_byte;
                recieve_state <= IDLE;
                data_recieved <= '1';
            when others =>
                recieve_state <= IDLE;
        end case;
    end if;
end process;

transmit: process(clock)
begin
    if rising_edge(clock) then
        case transmit_state is
            when IDLE => 
                tx <= '1';
                ready_for_transmit <= '1';
                transmit_bit_index <= x"0";
                if start_transmit = '1' then --wait for start command
                    transmit_byte <= D_in;
                    transmit_state <= SEND_BYTE;
                    tx <= '0'; --send start condition
                    ready_for_transmit <= '0';
                end if;
            when SEND_BYTE =>
                if transmit_bit_index /= x"8" then
                    tx <= transmit_byte(to_integer(transmit_bit_index));
                    transmit_bit_index <= transmit_bit_index+ x"1";
                else
                    tx <= '1'; --transmit stop bit before going idle
                    transmit_state <= IDLE;
                end if;
            when others =>
                transmit_state <= IDLE;
        end case;
    end if;
end process;

end architecture;

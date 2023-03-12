library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.STD_LOGIC_UNSIGNED.all;

entity hardware is
    port(
        rx : in std_logic;
        tx : out std_logic;
        setpoint: in signed (7 downto 0);
        ki,Kp,Kd: in signed(7 downto 0);
        clock: in std_logic
    );
    end entity;

architecture main of hardware is
    component PID is
        port(
            sample : in  signed(7 downto 0);
            setpoint: in signed (7 downto 0);
            output: out signed(7 downto 0) := x"00";
            Ki, Kd, Kp: in signed (7 downto 0);
            clock :in std_logic;
            transmit_ready: in std_logic;
            data_recieved: in std_logic;
            start_transmitting: out std_logic := '0'
        );
    end component;
    for PID0: PID use entity work.PID;
    
    component uart is 
        port(
            rx: in std_logic;
            D_out: out std_logic_vector(7 downto 0):=x"00";
            clock: in std_logic;
            D_in: in std_logic_vector(7 downto 0);
            tx: out std_logic:= '1';
            data_recieved: out std_logic;
            start_transmit: in std_logic;
            ready_for_transmit: out std_logic
        );
    end component;
    for uart0: uart use entity work.uart;
    signal DATA1, DATA2: std_logic_vector(7 downto 0) := x"00";
    signal data_recieved1 : std_logic;
    signal ready_for_transmit1 : std_logic;
    signal start_transmission1: std_logic;
begin
    PID0: PID port map(sample => signed(DATA1), std_logic_vector(output) => DATA2, clock => clock, setpoint => setpoint, 
                        Ki => Ki, Kp=>Kp, Kd => Kd, data_recieved=>data_recieved1,transmit_ready => ready_for_transmit1, start_transmitting => start_transmission1);
    uart0: uart port map(rx => rx, tx=>tx, D_out => DATA1, D_in => DATA2, clock => clock, data_recieved => data_recieved1, 
                        ready_for_transmit=> ready_for_transmit1, start_transmit => start_transmission1);
end architecture;

library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.STD_LOGIC_UNSIGNED.all;

entity testbench is
    end entity;

architecture main_tb of testbench is
    component hardware is 
    port(
        rx : in std_logic;
        tx : out std_logic;
        setpoint: in signed (7 downto 0);
        ki,Kp,Kd: in signed(7 downto 0);
        clock: in std_logic        
    );
    end component;
    for test: hardware use entity work.hardware;

    signal uart_tx, uart_rx, clock: std_logic;
    signal setpoint: signed (7 downto 0);
    signal ki,Kp,Kd: signed(7 downto 0);

    signal recieved_byte_tb: std_logic_vector( 7 downto 0);
    signal bit_index_tb :unsigned (3 downto 0):=x"0";
    constant IDLE: unsigned (3 downto 0):= x"0";
    constant RECIEVE_BYTE: unsigned ( 3 downto 0):= x"1";
    constant SEND_RECIEVED: unsigned(3 downto 0):=x"2";
    signal recieve_state_tb: unsigned (3 downto 0) := IDLE;

   signal recieve_data_tb, transmit_data_tb: signed ( 7 downto 0):= x"00";
   signal delay1, delay2, delay3, delay4, delay5: signed (7 downto 0):= x"00";
   signal data_recieved_tb: std_logic := '0';
   signal transmitting, start_transmission_tb: std_logic:= '0';
begin
    test: hardware port map( rx => uart_tx, tx => uart_rx, clock=> clock, Ki => Ki, Kp => Kp, Kd =>Kd, setpoint => setpoint);
    clk: process
    begin
        wait for 5 ns;
        clock <= '1';
        --sample <= testing;
        wait for 5 ns;
        clock <= '0';
    end process;
    
    --create serial data
    transmit: process
    begin
        uart_tx <= '1';
        transmitting <= '0';
        wait until rising_edge(start_transmission_tb); --wait until transmit order is given 
        transmitting <= '1';
        wait until rising_edge(clock);
        uart_tx <= '0'; --send start condition
        for transmit_index in 0 to 7 loop
            wait until rising_edge(clock);
            uart_tx <= transmit_data_tb(transmit_index);
        end loop;
        wait until rising_edge(clock);
        uart_tx <= '1';
        --report "data sended" severity note;
    end process;

    recieve: process(clock)
    begin
        if falling_edge(clock) then
            case recieve_state_tb is
                when IDLE =>
                    recieved_byte_tb <= x"00";
                    bit_index_tb <= x"0";
                    if uart_rx = '0' then --start condition detected;
                        recieve_state_tb <= RECIEVE_BYTE;
                        data_recieved_tb <= '0';
                    end if;
                when RECIEVE_BYTE => --recieve byte
                    if bit_index_tb /= x"8" then
                        recieved_byte_tb(to_integer(bit_index_tb)) <= uart_rx;
                        bit_index_tb <= bit_index_tb +1;
                    else
                        recieve_state_tb <= SEND_RECIEVED;
                    end if;
                when SEND_RECIEVED =>
                    data_recieved_tb <= '1';
                    recieve_data_tb <= signed(recieved_byte_tb);
                    --report "data recieved" severity note;
                    recieve_state_tb <= IDLE;
                when others =>
                    recieve_state_tb <= IDLE;
            end case;
        end if;
    end process;


    main: process
    begin
        --start values
        Ki <= x"01";
        Kp <= x"01";
        Kd <= x"01";
        setpoint <= x"0f";
        wait for 10 ns;
        transmit_data_tb <= x"56";
        start_transmission_tb <= '1';
        wait until rising_Edge (transmitting);
        start_transmission_tb <= '0';
        for loop_tb in 0 to 100 loop
            wait until rising_edge(data_recieved_tb);
            report "serial transmitted: " & integer'image(to_integer(transmit_data_tb)) severity note;
            report "setpoint: " & integer'image(to_integer(setpoint)) severity note;
            report "serial recieved: " & integer'image(to_integer(recieve_data_tb)) severity note;
            transmit_data_tb <= delay5;
            delay5<=delay4;
            delay4<=delay3;
            delay3<=delay2;
            delay2<=delay1;
            delay1<=recieve_data_tb;
            start_transmission_tb <= '1';
            wait until rising_Edge (transmitting);
            start_transmission_tb <= '0';
        end loop;
    report "end of sim" severity failure;
    end process;

end architecture;


library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.STD_LOGIC_UNSIGNED.all;

entity PID is
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
end entity PID;

architecture controller of PID is

    signal current_err, prev_err :integer:= 0;
    --signal test: signed (15 downto 0):=x"0000";
    signal I_action, P_action, D_action: integer:= 0;    --unlike addition and substraction, multiplication of (un)signed vector generates a bit length
    signal set, samp : integer := 0;
    signal total_action : signed (7 downto 0):= x"00";
    constant CALCULATE_ERROR: unsigned (3 downto 0):= x"0";
    constant DETERMINE_ACTIONS: unsigned (3 downto 0):= x"1";
    constant SET_OUTPUT: unsigned(3 downto 0):= x"2";
    constant IDLE: unsigned(3 downto 0):= x"3";
    constant CALCULATE_ACTION: unsigned (3 downto 0):=x"4";

    signal state : unsigned( 3 downto 0):=IDLE;
begin
    error: process(clock)
    begin
        if rising_edge(clock) then
            case state is
                when IDLE =>
                    start_transmitting <= '0';
                    if data_recieved = '1' then --wait until data is recieved
                        state <= CALCULATE_ERROR;
                    end if;
                when CALCULATE_ERROR => 
                    prev_err <= current_err;
                    current_err <= to_integer(setpoint)- to_integer(sample);
                    state <= DETERMINE_ACTIONS;
                when DETERMINE_ACTIONS =>
                    P_action <= to_integer(Kp)* current_err;
                    I_action <= to_integer(Ki)*(current_err+prev_err);
                    D_action <= to_integer(kd)*(current_err-prev_err);
                    state <= CALCULATE_ACTION;
                when CALCULATE_ACTION =>
                    total_action <= to_signed((P_action+I_action+D_action), 8);
                    state <= SET_OUTPUT;
                when SET_OUTPUT =>
                    if transmit_ready = '1' then --wait for transmit logic te be ready
                        start_transmitting <= '1';
                        output <= sample +total_action; 
                        state <= IDLE;
                    end if;
                when OTHERS =>
                    state <= IDLE;
                end case;
        end if;
    end process;
 end architecture;


 library ieee;
 use ieee.STD_LOGIC_1164.all;
 use ieee.numeric_std.all;
 use ieee.STD_LOGIC_UNSIGNED.all;
 --use std.TEXTIO.all;

 entity PID_tb is
    end entity;

architecture testbench of PID_tb is
    component PID is
        port(
        sample : in  signed(7 downto 0);
        setpoint: in signed (7 downto 0);
        output: out signed(7 downto 0);
        Ki, Kd, Kp: in signed (7 downto 0);
        clock :in std_logic
        );
    end component;

    for PID_test: PID use entity work.PID;

    signal sample :signed(7 downto 0):= x"00";
    signal setpoint:signed (7 downto 0):= x"00";
    signal output: signed(7 downto 0):= x"00";
    signal Ki, Kd, Kp: signed (7 downto 0):= x"00";
    signal clock :std_logic := '0';
    signal testing: signed (7 downto 0):= x"00";

begin
    PID_test: PID port map( sample => sample, setpoint => setpoint, output => output, Ki=>Ki, Kd => Kd, Kp => Kp, clock => clock);
    process
    begin
        wait for 5 ns;
        clock <= '1';
        --sample <= testing;
        wait for 5 ns;
        clock <= '0';
        sample <= output;
    end process;
    
    reports: process(output, setpoint, sample)
    begin
        report "setpoint = " & integer'image(to_integer(setpoint)) severity note;
        report "output = " & integer'image(to_integer(output)) severity note;
        report "sample = " & integer'image(to_integer(sample)) severity note;
    end process reports;

    main: process
    begin
        setpoint <= x"00";
        --sample <= x"00";
        Ki <= x"01";
        Kp <= x"01";
        kd <= x"01";
        wait until rising_edge(clock);
        --lets plot a response
        setpoint <= x"0f";
         wait for 10000 ns;
        report "end of sim" severity failure;
    end process;
end architecture;
    
    
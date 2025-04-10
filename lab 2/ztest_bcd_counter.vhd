library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_bcd_counter is
end entity;

architecture tb of test_bcd_counter is
    signal Clk       : std_logic := '0';
    signal Reset     : std_logic := '0';
    signal Enable    : std_logic := '1';
    signal Direction : std_logic := '1';
    signal Q_Out     : std_logic_vector(3 downto 0);

    component BCD_Counter
        port (
            Clk       : in  std_logic;
            Reset     : in  std_logic;
            Enable    : in  std_logic;
            Direction : in  std_logic;
            Q_Out     : out std_logic_vector(3 downto 0)
        );
    end component;
begin
    -- Connect Unit Under Test (UUT)
    uut: BCD_Counter
        port map (
            Clk       => Clk,
            Reset     => Reset,
            Enable    => Enable,
            Direction => Direction,
            Q_Out     => Q_Out
        );

    -- Clock generation: 100 MHz (10 ns period)
    clock_gen: process
    begin
        while true loop
            Clk <= '0';
            wait for 5 ns;
            Clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    -- Direction toggling every 200 ns
    direction_toggle: process
    begin
        while true loop
            wait for 200 ns;
            Direction <= not Direction;
        end loop;
    end process;

    -- Reset pulse every 100 ns (lasting 10 ns)
    periodic_reset: process
    begin
        while true loop
            wait for 100 ns;
            Reset <= '1';
            wait for 10 ns;
            Reset <= '0';
        end loop;
    end process;

end architecture;

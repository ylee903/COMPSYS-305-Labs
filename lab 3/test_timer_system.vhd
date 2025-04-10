library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity test_timer_system is
end entity;

architecture tb of test_timer_system is

    -- Clock frequency: 50 MHz = 20 ns period
    constant CLOCK_PERIOD : time := 20 ns;

    signal Clk     : std_logic := '0';
    signal Reset   : std_logic := '0';
    signal Enable  : std_logic := '1';

    signal Q_Ones  : std_logic_vector(3 downto 0);
    signal Q_Tens  : std_logic_vector(3 downto 0);

    signal SEG_Ones : std_logic_vector(6 downto 0);
    signal SEG_Tens : std_logic_vector(6 downto 0);

    -- COMPONENT declarations
    component BCD_Counter
        port (
            Clk       : in  std_logic;
            Reset     : in  std_logic;
            Enable    : in  std_logic;
            Direction : in  std_logic;
            Q_Out     : out std_logic_vector(3 downto 0)
        );
    end component;

    component BCD_to_SevenSeg
        port (
            BCD_digit     : in std_logic_vector(3 downto 0);
            SevenSeg_out  : out std_logic_vector(6 downto 0)
        );
    end component;

    signal Tens_Enable : std_logic := '0';

begin

    -- Clock generation
    clock_proc: process
    begin
        while true loop
            Clk <= '0';
            wait for CLOCK_PERIOD / 2;
            Clk <= '1';
            wait for CLOCK_PERIOD / 2;
        end loop;
    end process;

    -- Timer system: two BCD counters (00 to 99)
    ones_counter: BCD_Counter
        port map (
            Clk       => Clk,
            Reset     => Reset,
            Enable    => Enable,
            Direction => '1', -- count up
            Q_Out     => Q_Ones
        );

    tens_counter: BCD_Counter
        port map (
            Clk       => Clk,
            Reset     => Reset,
            Enable    => Tens_Enable,
            Direction => '1',
            Q_Out     => Q_Tens
        );

    -- Tens Enable logic: fire when ones is at 9
    process (Clk)
    begin
        if rising_edge(Clk) then
            if Reset = '1' then
                Tens_Enable <= '0';
            elsif Enable = '1' and Q_Ones = "1001" then
                Tens_Enable <= '1';
            else
                Tens_Enable <= '0';
            end if;
        end if;
    end process;

    -- Connect to 7-segment decoder
    ones_seg: BCD_to_SevenSeg
        port map (
            BCD_digit     => Q_Ones,
            SevenSeg_out  => SEG_Ones
        );

    tens_seg: BCD_to_SevenSeg
        port map (
            BCD_digit     => Q_Tens,
            SevenSeg_out  => SEG_Tens
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- Initial Reset
        Reset <= '1';
        wait for 40 ns;
        Reset <= '0';

        -- Let it count to simulate full 00 to 99
        wait for 2000 ns;

        -- Optional: Disable and re-enable
        Enable <= '0';
        wait for 100 ns;
        Enable <= '1';

        -- End simulation
        wait;
    end process;

end architecture;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY test_timer_system IS
END ENTITY;

ARCHITECTURE behavior OF test_timer_system IS

    -- DUT Declaration
    COMPONENT three_digit_timer
        PORT (
            Clk       : IN  STD_LOGIC;
            Reset     : IN  STD_LOGIC;
            Enable    : IN  STD_LOGIC;
            Min_ones  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            Sec_tens  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            Sec_ones  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT BCD_to_SevenSeg
        PORT (
            BCD_digit : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            SevenSeg_out : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT;

    -- Signals for Timer
    SIGNAL Clk      : STD_LOGIC := '0';
    SIGNAL Reset    : STD_LOGIC := '0';
    SIGNAL Enable   : STD_LOGIC := '0';
    SIGNAL Min_ones : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL Sec_tens : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL Sec_ones : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- Signals for Seven Segment Outputs
    SIGNAL seg_min_ones : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL seg_sec_tens : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL seg_sec_ones : STD_LOGIC_VECTOR(6 DOWNTO 0);

BEGIN

    -- Instantiate Timer System
    uut: three_digit_timer
        PORT MAP (
            Clk      => Clk,
            Reset    => Reset,
            Enable   => Enable,
            Min_ones => Min_ones,
            Sec_tens => Sec_tens,
            Sec_ones => Sec_ones
        );

    -- Instantiate BCD to Seven Segment Converters
    min_ones_disp : BCD_to_SevenSeg
        PORT MAP (
            BCD_digit => Min_ones,
            SevenSeg_out => seg_min_ones
        );

    sec_tens_disp : BCD_to_SevenSeg
        PORT MAP (
            BCD_digit => Sec_tens,
            SevenSeg_out => seg_sec_tens
        );

    sec_ones_disp : BCD_to_SevenSeg
        PORT MAP (
            BCD_digit => Sec_ones,
            SevenSeg_out => seg_sec_ones
        );

    -- Clock Generation 50 MHz
    Clk_process : PROCESS
    BEGIN
        Clk <= '0';
        WAIT FOR 10 ns;
        Clk <= '1';
        WAIT FOR 10 ns;
    END PROCESS;

    -- Stimulus
    Stim_proc : PROCESS
    BEGIN
        Reset <= '1';
        WAIT FOR 100 ns;
        Reset <= '0';

        Enable <= '1';

        -- Simulate 70 seconds of counting
        WAIT FOR 250 * 1000000000 ns / 50e6; 

        Enable <= '0';

        WAIT FOR 200 ns;

        Reset <= '1';
        WAIT FOR 50 ns;
        Reset <= '0';

        WAIT FOR 500 ns;

        WAIT;
    END PROCESS;

END ARCHITECTURE;



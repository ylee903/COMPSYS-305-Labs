LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY top_level_timer IS
    PORT (
        CLOCK_50 : IN STD_LOGIC;
        SW       : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        KEY      : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        LEDR     : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        HEX0     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE Behavioral OF top_level_timer IS

    -- Clock divider for 1Hz
    SIGNAL clk_divider : unsigned(25 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tick_1hz    : STD_LOGIC := '0';

    -- Timer outputs
    SIGNAL Q_sec_ones, Q_sec_tens, Q_min_ones : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- Control signals
    SIGNAL Reset              : STD_LOGIC := '0';
    SIGNAL Enable             : STD_LOGIC := '0';
    SIGNAL send_Enable_1     : STD_LOGIC := '0';
    SIGNAL send_Enable_2     : STD_LOGIC := '1';
    SIGNAL send_Reset        : STD_LOGIC := '0';

    -- Captured and capped target values from SW
    SIGNAL target_sec_ones   : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL target_sec_tens   : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL target_min_ones   : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');

    -- Debug signals from timer
    SIGNAL debug_stop_1, debug_stop_2, debug_stop_3 : STD_LOGIC;

BEGIN

    -- === 1 Hz Clock Divider ===
    PROCESS (CLOCK_50)
    BEGIN
        IF rising_edge(CLOCK_50) THEN
            IF clk_divider = 49_999_999 THEN
                clk_divider <= (OTHERS => '0');
                tick_1hz <= '1';
            ELSE
                clk_divider <= clk_divider + 1;
                tick_1hz <= '0';
            END IF;
        END IF;
    END PROCESS;

    -- === Button Trigger: Capture SW, Cap, and Start ===
    PROCESS (CLOCK_50)
        VARIABLE sw_ones : unsigned(3 DOWNTO 0);
        VARIABLE sw_tens : unsigned(3 DOWNTO 0);
        VARIABLE sw_mins : unsigned(1 DOWNTO 0);
    BEGIN
        IF rising_edge(CLOCK_50) THEN
            IF KEY(0) = '0' THEN  -- Button press (active-low)
                -- Capture & cap values
                sw_ones := unsigned(SW(3 DOWNTO 0));
                IF sw_ones > 9 THEN
                    target_sec_ones <= "1001";
                ELSE
                    target_sec_ones <= std_logic_vector(sw_ones);
                END IF;

                sw_tens := unsigned(SW(7 DOWNTO 4));
                IF sw_tens > 5 THEN
                    target_sec_tens <= "0101";
                ELSE
                    target_sec_tens <= std_logic_vector(sw_tens);
                END IF;

                sw_mins := unsigned(SW(9 DOWNTO 8));
                IF sw_mins > 3 THEN
                    target_min_ones <= "0011";
                ELSE
                    target_min_ones <= "00" & std_logic_vector(sw_mins);
                END IF;

                -- Trigger reset + enable
                send_Enable_1 <= '1';
                send_Reset    <= '1';
            ELSE
                send_Reset <= '0';
            END IF;
        END IF;
    END PROCESS;

    -- === Timer Stop Condition ===
    PROCESS (CLOCK_50)
    BEGIN
        IF rising_edge(CLOCK_50) THEN
            IF Enable = '1' THEN
                IF Q_min_ones = target_min_ones AND
                   Q_sec_tens = target_sec_tens AND
                   Q_sec_ones = target_sec_ones THEN
                    send_Enable_2 <= '0';  -- Stop
                END IF;
            ELSE
                IF KEY(0) = '0' THEN
                    send_Enable_2 <= '1';  -- Restart enable
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Final control logic
    Reset  <= send_Reset;
    Enable <= send_Enable_1 AND send_Enable_2;

    -- === Timer Component ===
    timer_inst : entity work.three_digit_timer
        PORT MAP (
            Clk           => tick_1hz,
            Reset         => Reset,
            Enable        => Enable,
            Min_ones      => Q_min_ones,
            Sec_tens      => Q_sec_tens,
            Sec_ones      => Q_sec_ones,
            debug_stop_1  => debug_stop_1,
            debug_stop_2  => debug_stop_2,
            debug_stop_3  => debug_stop_3
        );

    -- === 7-Segment Converters ===
    seg0 : entity work.BCD_to_SevenSeg
        PORT MAP (BCD_digit => Q_sec_ones, SevenSeg_out => HEX0);

    seg1 : entity work.BCD_to_SevenSeg
        PORT MAP (BCD_digit => Q_sec_tens, SevenSeg_out => HEX1);

    seg2 : entity work.BCD_to_SevenSeg
        PORT MAP (BCD_digit => Q_min_ones, SevenSeg_out => HEX2);

    -- === LED Indicators ===
    LEDR(0) <= Enable;
    LEDR(1) <= Reset;
    LEDR(2) <= debug_stop_1;
    LEDR(3) <= debug_stop_2;
    LEDR(4) <= NOT send_Enable_2;  -- Time_Out signal

END ARCHITECTURE;

-- Include the IEEE standard library for basic logic types
LIBRARY IEEE;
-- Include standard logic definitions (e.g., std_logic, std_logic_vector)
USE IEEE.STD_LOGIC_1164.ALL;
-- Include arithmetic operations on unsigned/signed types
USE IEEE.NUMERIC_STD.ALL;

-- Entity declaration for the top-level timer system
ENTITY top_level_timer IS
    PORT (
        CLOCK_50 : IN STD_LOGIC; -- 50 MHz system clock input
        SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0); -- 10 input switches (used for setting time in later tasks)
        KEY : IN STD_LOGIC_VECTOR(0 DOWNTO 0); -- Push button input (used for starting the timer in later tasks)
        LEDR : OUT STD_LOGIC_VECTOR(0 DOWNTO 0); -- Single LED output (optional debug indicator)
        HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- Seven-segment output for Seconds Ones place
        HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- Seven-segment output for Seconds Tens place
        HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- Seven-segment output for Minutes Ones place
    );
END ENTITY;

-- Architecture body for top_level_timer
ARCHITECTURE Behavioral OF top_level_timer IS

    -- === Internal Signal Declarations ===

    SIGNAL clk_divider : unsigned(25 DOWNTO 0) := (OTHERS => '0'); -- 26-bit counter for clock division (counts to 9,999,999)
    SIGNAL one_hz_clk : STD_LOGIC := '0'; -- Divided clock signal toggling at 1 Hz
    SIGNAL Q_sec_ones : STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit BCD output for Seconds Ones digit
    SIGNAL Q_sec_tens : STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit BCD output for Seconds Tens digit
    SIGNAL Q_min_ones : STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit BCD output for Minutes Ones digit
    SIGNAL Enable : STD_LOGIC := '1'; -- Enable signal (active high, always enabled here)
    SIGNAL Reset : STD_LOGIC := '0'; -- Reset signal (active high, unused here)
    SIGNAL tick_1hz : STD_LOGIC := '0'; -- One-cycle pulse indicating a 1Hz clock tick

    -- === Component Declarations ===

    -- Declare the three-digit timer component (external module)
    COMPONENT three_digit_timer
        PORT (
            Clk : IN STD_LOGIC; -- Clock input (expected to be 1 Hz)
            Reset : IN STD_LOGIC; -- Active-high reset input
            Enable : IN STD_LOGIC; -- Active-high enable input
            Min_ones : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- Minutes Ones BCD output
            Sec_tens : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- Seconds Tens BCD output
            Sec_ones : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) -- Seconds Ones BCD output
        );
    END COMPONENT;

    -- Declare the BCD-to-SevenSegment decoder component
    COMPONENT BCD_to_SevenSeg
        PORT (
            BCD_digit : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit BCD input
            SevenSeg_out : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- Corresponding 7-segment output
        );
    END COMPONENT;

BEGIN

    -- === Clock Divider Process ===
    -- Purpose: Convert 50 MHz input clock into a 1 Hz pulse (tick_1hz) and toggling clock (one_hz_clk)
    PROCESS (CLOCK_50)
    BEGIN
        IF rising_edge(CLOCK_50) THEN -- Detect rising edge of 50 MHz clock
            IF clk_divider = 9_999_999 THEN -- If counter reaches 10 million ticks (1 second)
                clk_divider <= (OTHERS => '0'); -- Reset the divider counter
                one_hz_clk <= NOT one_hz_clk; -- Toggle the 1 Hz clock signal
                tick_1hz <= '1'; -- Generate a 1-cycle wide pulse (tick)
            ELSE
                clk_divider <= clk_divider + 1; -- Otherwise, increment the divider counter
                tick_1hz <= '0'; -- Clear the tick pulse
            END IF;
        END IF;
    END PROCESS;

    -- === Timer Instance ===
    -- Connects the 1 Hz tick to a three-digit BCD-based timer
    timer_inst : three_digit_timer
    PORT MAP(
        Clk => tick_1hz, -- Connect 1Hz pulse to clock input
        Reset => Reset, -- Connect reset signal (inactive here)
        Enable => Enable, -- Connect enable signal (always enabled)
        Min_ones => Q_min_ones, -- Connect to internal minutes ones signal
        Sec_tens => Q_sec_tens, -- Connect to internal seconds tens signal
        Sec_ones => Q_sec_ones -- Connect to internal seconds ones signal
    );

    -- === Seven-Segment Display Mapping ===

    -- Map Seconds Ones (Q_sec_ones) to HEX0
    seg0 : BCD_to_SevenSeg
    PORT MAP(
        BCD_digit => Q_sec_ones, -- Connect BCD input
        SevenSeg_out => HEX0 -- Drive segment output
    );

    -- Map Seconds Tens (Q_sec_tens) to HEX1
    seg1 : BCD_to_SevenSeg
    PORT MAP(
        BCD_digit => Q_sec_tens, -- Connect BCD input
        SevenSeg_out => HEX1 -- Drive segment output
    );

    -- Map Minutes Ones (Q_min_ones) to HEX2
    seg2 : BCD_to_SevenSeg
    PORT MAP(
        BCD_digit => Q_min_ones, -- Connect BCD input
        SevenSeg_out => HEX2 -- Drive segment output
    );

    -- === Debug Output (Optional) ===
    -- LEDR(0) is currently hardcoded to '0' and not used
    LEDR(0) <= '0';

END ARCHITECTURE;
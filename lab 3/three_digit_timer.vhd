-- Include the IEEE library (standard library for VHDL)
LIBRARY IEEE;
-- Use the standard logic package (defines std_logic and std_logic_vector)
USE IEEE.STD_LOGIC_1164.ALL;
-- Use the numeric standard package (provides arithmetic operations)
USE IEEE.NUMERIC_STD.ALL;

-- Define the entity for the three-digit timer
ENTITY three_digit_timer IS
    PORT (
        Clk : IN STD_LOGIC; -- Clock input signal
        Reset : IN STD_LOGIC; -- Asynchronous reset input (active high)
        Enable : IN STD_LOGIC; -- Enable input (active high)
        Min_ones : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- Minutes ones digit output (BCD 0–3)
        Sec_tens : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- Seconds tens digit output (BCD 0–5)
        Sec_ones : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) -- Seconds ones digit output (BCD 0–9)
    );
END ENTITY;

-- Architecture body begins, named 'structural' to reflect component usage
ARCHITECTURE structural OF three_digit_timer IS

    -- === Internal signal declarations ===

    SIGNAL s_sec_ones : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Stores seconds ones value
    SIGNAL s_sec_tens : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Stores seconds tens value
    SIGNAL s_min_ones : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Stores minutes ones value

    SIGNAL en_sec_tens : STD_LOGIC := '0'; -- Enable for seconds tens counter
    SIGNAL en_min_ones : STD_LOGIC := '0'; -- Enable for minutes ones counter
    SIGNAL reset_seconds : STD_LOGIC := '0'; -- Signal to reset seconds counters
    SIGNAL reset_timer : STD_LOGIC := '0'; -- Signal to reset the entire timer

    -- === Component declaration ===
    -- BCD_Counter is a 4-bit Binary-Coded Decimal counter component
    COMPONENT BCD_Counter
        PORT (
            Clk : IN STD_LOGIC; -- Clock input
            Reset : IN STD_LOGIC; -- Asynchronous reset input
            Enable : IN STD_LOGIC; -- Enable input
            Direction : IN STD_LOGIC; -- Direction input: '1' for up count
            Q_Out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)-- 4-bit BCD counter output
        );
    END COMPONENT;

BEGIN

    -- === Seconds Ones Digit (0–9) ===
    -- Instantiates a BCD_Counter for seconds ones place
    sec_ones_inst : BCD_Counter
    PORT MAP(
        Clk => Clk, -- Connect clock input
        Reset => Reset OR reset_seconds OR reset_timer, -- Reset if global reset, seconds reset, or full timer reset is active
        Enable => Enable, -- Always count when enabled
        Direction => '1', -- Count up (increment)
        Q_Out => s_sec_ones -- Output connected to internal signal
    );

    -- === Logic to Enable Seconds Tens ===
    -- Triggered when seconds ones digit is about to roll over from 8 to 9
    PROCESS (Clk)
    BEGIN
        IF rising_edge(Clk) THEN -- On rising edge of clock
            IF Reset = '1' THEN -- If global reset is active
                en_sec_tens <= '0'; -- Disable seconds tens
            ELSIF Enable = '1' AND s_sec_ones = "1000" THEN -- If counting is enabled and seconds ones is at 8
                en_sec_tens <= '1'; -- Enable seconds tens to increment on next tick
            ELSE
                en_sec_tens <= '0'; -- Otherwise keep it disabled
            END IF;
        END IF;
    END PROCESS;

    -- === Seconds Tens Digit (0–5) ===
    -- Instantiates a BCD_Counter for seconds tens place
    sec_tens_inst : BCD_Counter
    PORT MAP(
        Clk => Clk, -- Connect clock
        Reset => Reset OR reset_seconds OR reset_timer, -- Reset on global/seconds/full reset
        Enable => en_sec_tens, -- Enabled only when seconds ones rolls over
        Direction => '1', -- Count up
        Q_Out => s_sec_tens -- Output signal
    );

    -- === Logic to Enable Minutes Ones ===
    -- Triggered when the time is at 58 seconds (anticipating 59)
    PROCESS (Clk)
    BEGIN
        IF rising_edge(Clk) THEN
            IF Reset = '1' THEN -- On reset
                en_min_ones <= '0'; -- Disable minutes counter
            ELSIF Enable = '1' AND s_sec_ones = "1000" AND s_sec_tens = "0101" THEN
                -- If seconds is at 58, get ready to increment minutes ones
                en_min_ones <= '1';
            ELSE
                en_min_ones <= '0'; -- Otherwise, keep disabled
            END IF;
        END IF;
    END PROCESS;

    -- === Logic to Reset Seconds ===
    -- When the seconds reaches 59, reset both seconds ones and seconds tens
    PROCESS (Clk)
    BEGIN
        IF rising_edge(Clk) THEN
            IF Reset = '1' THEN -- On reset
                reset_seconds <= '0'; -- Clear the seconds reset
            ELSIF Enable = '1' AND s_sec_ones = "1000" AND s_sec_tens = "0101" THEN
                -- If seconds = 58, prepare to reset on next tick
                reset_seconds <= '1';
            ELSE
                reset_seconds <= '0'; -- Otherwise no reset
            END IF;
        END IF;
    END PROCESS;

    -- === Logic to Reset the Entire Timer ===
    -- When the time reaches 3:59 (anticipating 4:00), reset the whole timer
    PROCESS (Clk)
    BEGIN
        IF rising_edge(Clk) THEN
            IF Reset = '1' THEN -- On global reset
                reset_timer <= '0'; -- Deactivate timer reset
            ELSIF Enable = '1' AND s_sec_ones = "1000"
                AND s_sec_tens = "0101"
                AND s_min_ones = "0011" THEN
                -- If time is 3:58, prepare to reset whole timer on next tick
                reset_timer <= '1';
            ELSE
                reset_timer <= '0'; -- Otherwise, keep disabled
            END IF;
        END IF;
    END PROCESS;

    -- === Minutes Ones Digit (0–3) ===
    -- Instantiates a BCD_Counter for minutes ones place
    min_ones_inst : BCD_Counter
    PORT MAP(
        Clk => Clk, -- Connect clock
        Reset => Reset OR reset_timer, -- Reset on global or full timer reset
        Enable => en_min_ones, -- Enable based on logic from above
        Direction => '1', -- Count up
        Q_Out => s_min_ones -- Output signal
    );

    -- === Output Assignments ===
    -- Connect internal BCD counter outputs to entity outputs
    Sec_ones <= s_sec_ones; -- Connect seconds ones output
    Sec_tens <= s_sec_tens; -- Connect seconds tens output
    Min_ones <= s_min_ones; -- Connect minutes ones output

END ARCHITECTURE;
-- Include the IEEE standard library for basic logic types
LIBRARY IEEE;
-- Include standard logic definitions (e.g., std_logic, std_logic_vector)
USE IEEE.STD_LOGIC_1164.ALL;
-- Include arithmetic operations on unsigned/signed types
USE IEEE.NUMERIC_STD.ALL;

-- We are declaring the entity called top_level_timer.
-- In VHDL, an entity is like the outer shell or blueprint of a hardware component. 
-- It defines what inputs and outputs the component has — kind of like the pins on a physical chip.
ENTITY top_level_timer IS
    --🟢 We’re naming our top-level design module "top_level_timer".
    -- This is the "box" that will contain the logic for the entire digital timer system.
    -- Later, in the architecture, we will describe what this box does internally, but right now we're just describing its interface — the inputs and outputs.

    PORT (-- 🟢 We are now starting the port list — this is where we list all the inputs and outputs to/from this timer system. Think of these like cables that go in and out of the chip.
        CLOCK_50 : IN STD_LOGIC; -- 50 MHz system clock input
        SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0); -- 10 input switches (used for setting time in later tasks)
        KEY : IN STD_LOGIC_VECTOR(0 DOWNTO 0); -- Push button input (used for starting the timer in later tasks)
        LEDR : OUT STD_LOGIC_VECTOR(0 DOWNTO 0); -- Single LED output (optional debug indicator)
        HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- Seven-segment output for Seconds Ones place
        HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- Seven-segment output for Seconds Tens place
        HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- Seven-segment output for Minutes Ones place
    );
END ENTITY;

-- Architecture body for top_level_timer This block describes how the top-level timer circuit behaves and connects together internally. 
--It is like the "brain" of the top_level_timer entity: it wires up components (like a timer and display) and defines how signals behave over time.
--We're doing three big things here: ceclare internal signals, declaring (instantiate) components (like the timer and display), Describing internal behavior and connections
ARCHITECTURE Behavioral OF top_level_timer IS

    -- === Internal Signal Declarations === These are like internal "wires" or "variables" that store values or move data between parts of your design:

    SIGNAL clk_divider : unsigned(25 DOWNTO 0) := (OTHERS => '0'); -- 26-bit counter for clock division (counts to 49,999,999)
    SIGNAL Q_sec_ones : STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit BCD output for Seconds Ones digit
    SIGNAL Q_sec_tens : STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit BCD output for Seconds Tens digit
    SIGNAL Q_min_ones : STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit BCD output for Minutes Ones digit
    SIGNAL Enable : STD_LOGIC := '0'; -- Enable signal (active high, always enabled here)
    SIGNAL Reset : STD_LOGIC := '0'; -- Reset signal (active high, unused here)
    SIGNAL tick_1hz : STD_LOGIC := '0'; -- One-cycle pulse indicating a 1Hz clock tick
    SIGNAL one_hz_clk : STD_LOGIC := '0'; -- Divided clock signal toggling at 1 Hz

    SIGNAL last_key : STD_LOGIC := '1'; -- Last state of KEY[0] (push button) for edge detection

    SIGNAL timer_reset : STD_LOGIC := '0';

    SIGNAL start_latched : STD_LOGIC := '0';

    SIGNAL key_falling : STD_LOGIC := '0';

    SIGNAL Target_Min : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Target_SecT : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Target_SecO : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL max_reached : STD_LOGIC := '0';
    -- === Component Declarations === These are external modules (like building blocks) that we plan to use inside this design.

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

    -- Detect falling edge on KEY[0] to start counting
    PROCESS (CLOCK_50)

        VARIABLE tmp_sec_ones : UNSIGNED(3 DOWNTO 0);
        VARIABLE tmp_sec_tens : UNSIGNED(3 DOWNTO 0);
        VARIABLE tmp_min_ones : UNSIGNED(3 DOWNTO 0);

    BEGIN
        IF rising_edge(CLOCK_50) THEN
            -- Detect falling edge
            IF last_key = '1' AND KEY(0) = '0' THEN
                key_falling <= '1';
            ELSE
                key_falling <= '0';
            END IF;
            last_key <= KEY(0);

            -- On falling edge of KEY(0): latch SW values, cap, subtract 1, store target
            IF key_falling = '1' THEN
                -- Read switches
                tmp_sec_ones := UNSIGNED(SW(3 DOWNTO 0));
                tmp_sec_tens := UNSIGNED(SW(7 DOWNTO 4));
                tmp_min_ones := UNSIGNED("00" & SW(9 DOWNTO 8));

                -- Cap values
                IF tmp_sec_ones > 9 THEN
                    tmp_sec_ones := "1001";
                END IF;
                IF tmp_sec_tens > 5 THEN
                    tmp_sec_tens := "0101";
                END IF;
                IF tmp_min_ones > 3 THEN
                    tmp_min_ones := "0011";
                END IF;


                -- Store final target values
                Target_SecO <= STD_LOGIC_VECTOR(tmp_sec_ones);
                Target_SecT <= STD_LOGIC_VECTOR(tmp_sec_tens);
                Target_Min <= STD_LOGIC_VECTOR(tmp_min_ones);

                -- Reset and start timer
                Reset <= '1';
                Enable <= '1';
                max_reached <= '0';
            ELSE
                Reset <= '0'; -- Only pulse reset for 1 cycle
            END IF;

            -- Check if timer reached stored target
            IF Q_min_ones = Target_Min AND Q_sec_tens = Target_SecT AND Q_sec_ones = Target_SecO THEN
                max_reached <= '1';
            END IF;

            -- Disable timer when target time reached
            IF max_reached = '1' THEN
                Enable <= '0';
            END IF;
        END IF;
    END PROCESS;
    -- === Clock Divider Process ===
    -- Purpose: Convert 50 MHz input clock into a 1 Hz pulse (tick_1hz) and toggling clock (one_hz_clk)
    PROCESS (CLOCK_50)
    BEGIN
        IF rising_edge(CLOCK_50) THEN -- Detect rising edge of 50 MHz clock
            IF clk_divider = 4_999_999 THEN -- 49_999_999 for 1 hz, 9_999_999 for 10 hz , 999_999 for 100 hz
                clk_divider <= (OTHERS => '0'); -- (set all bits set to zero) assign to all 26 bits of clk_divider
                one_hz_clk <= NOT one_hz_clk; -- Toggle the 1 Hz clock signal
                tick_1hz <= '1'; -- Generate a 1-cycle wide pulse (tick), this is done by imediatly in the next tick chaing to 0 under "Else"
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
        Reset => timer_reset, -- Connect reset signal (inactive here)
        Enable => Enable, -- Connect enable signal
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
    LEDR(0) <= Enable;
END ARCHITECTURE;
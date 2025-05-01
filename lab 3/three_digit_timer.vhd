LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY three_digit_timer IS
    PORT (
        Clk : IN STD_LOGIC;
        Reset : IN STD_LOGIC;
        Enable : IN STD_LOGIC;
        Min_ones : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        Sec_tens : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        Sec_ones : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        debug_stop_1 : OUT STD_LOGIC;
        debug_stop_2 : OUT STD_LOGIC;
        debug_stop_3 : OUT STD_LOGIC
    );
END ENTITY;

ARCHITECTURE structural OF three_digit_timer IS
    SIGNAL s_sec_ones, s_sec_tens, s_min_ones : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL en_sec_tens, en_min_ones, reset_sec_tens : STD_LOGIC := '0';

    COMPONENT BCD_Counter
        PORT (
            Clk : IN STD_LOGIC;
            Reset : IN STD_LOGIC;
            Enable : IN STD_LOGIC;
            Direction : IN STD_LOGIC;
            Q_Out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;

BEGIN

    sec_ones_inst : BCD_Counter
    PORT MAP(
        Clk => Clk,
        Reset => Reset OR (reset_sec_tens AND Enable),
        Enable => Enable,
        Direction => '1',
        Q_Out => s_sec_ones
    );

    PROCESS (Clk)
    BEGIN
        IF rising_edge(Clk) THEN
            IF Reset = '1' THEN
                en_sec_tens <= '0';
            ELSIF Enable = '1' AND s_sec_ones = "1001" THEN
                en_sec_tens <= '1';
            ELSE
                en_sec_tens <= '0';
            END IF;
        END IF;
    END PROCESS;

    sec_tens_inst : BCD_Counter
    PORT MAP(
        Clk => Clk,
        Reset => Reset OR (reset_sec_tens AND Enable),
        Enable => en_sec_tens,
        Direction => '1',
        Q_Out => s_sec_tens
    );

    PROCESS (Clk)
    BEGIN
        IF rising_edge(Clk) THEN
            IF Enable = '1' THEN
                IF s_sec_ones = "1001" AND s_sec_tens = "0101" THEN
                    reset_sec_tens <= '1';
                ELSE
                    reset_sec_tens <= '0';
                END IF;
            ELSE
                reset_sec_tens <= '0';
            END IF;
        END IF;
    END PROCESS;

    PROCESS (Clk)
    BEGIN
        IF rising_edge(Clk) THEN
            IF Reset = '1' THEN
                en_min_ones <= '0';
            ELSIF Enable = '1' AND s_sec_ones = "1001" AND s_sec_tens = "0101" THEN
                en_min_ones <= '1';
            ELSE
                en_min_ones <= '0';
            END IF;
        END IF;
    END PROCESS;

    min_ones_inst : BCD_Counter
    PORT MAP(
        Clk => Clk,
        Reset => Reset,
        Enable => en_min_ones,
        Direction => '1',
        Q_Out => s_min_ones
    );

    -- Output
    Sec_ones <= s_sec_ones;
    Sec_tens <= s_sec_tens;
    Min_ones <= s_min_ones;

    -- Debug LEDs
    debug_stop_1 <= en_sec_tens;
    debug_stop_2 <= reset_sec_tens;
    debug_stop_3 <= Enable;

END ARCHITECTURE;

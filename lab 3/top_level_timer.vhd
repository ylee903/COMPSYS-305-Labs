library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level_timer is
    port (
        CLOCK_50 : in  STD_LOGIC;
        SW       : in  STD_LOGIC_VECTOR(9 downto 0);
        KEY      : in  STD_LOGIC_VECTOR(0 downto 0);
        LEDR     : out STD_LOGIC_VECTOR(0 downto 0);
        HEX0     : out STD_LOGIC_VECTOR(6 downto 0);  -- Sec Ones
        HEX1     : out STD_LOGIC_VECTOR(6 downto 0);  -- Sec Tens
        HEX2     : out STD_LOGIC_VECTOR(6 downto 0)   -- Min Ones
    );
end entity;

architecture Behavioral of top_level_timer is

    -- Internal Signals
    signal clk_divider  : unsigned(25 downto 0) := (others => '0');
    signal one_hz_clk   : std_logic := '0';
    signal Q_sec_ones   : std_logic_vector(3 downto 0);
    signal Q_sec_tens   : std_logic_vector(3 downto 0);
    signal Q_min_ones   : std_logic_vector(3 downto 0);
    signal Enable       : std_logic := '1';
    signal Reset        : std_logic := '0';
    signal tick_1hz : std_logic := '0';
    


    -- Components
    component three_digit_timer
        port (
            Clk       : in  std_logic;
            Reset     : in  std_logic;
            Enable    : in  std_logic;
            Min_ones  : out std_logic_vector(3 downto 0);
            Sec_tens  : out std_logic_vector(3 downto 0);
            Sec_ones  : out std_logic_vector(3 downto 0)
        );
    end component;

    component BCD_to_SevenSeg
        port (
            BCD_digit     : in  std_logic_vector(3 downto 0);
            SevenSeg_out  : out std_logic_vector(6 downto 0)
        );
    end component;

begin

    -- Clock Divider: Generates 1 Hz clock from 50 MHz
    process (CLOCK_50)
    begin
        -- clk_divider = 9_999_999
        if rising_edge(CLOCK_50) then
            if clk_divider = 9_999_999 then 
                clk_divider <= (others => '0');
                one_hz_clk <= not one_hz_clk;
                tick_1hz <= '1';  -- 1-cycle pulse
            else
                clk_divider <= clk_divider + 1;
                tick_1hz <= '0';
            end if;
        end if;
    end process;

    -- Instantiate the three-digit timer
    timer_inst : three_digit_timer
        port map (
            Clk       => tick_1hz,
            Reset     => Reset,
            Enable    => Enable,
            Min_ones  => Q_min_ones,
            Sec_tens  => Q_sec_tens,
            Sec_ones  => Q_sec_ones
        );

    -- 7-segment decoding
    seg0 : BCD_to_SevenSeg
        port map (
            BCD_digit     => Q_sec_ones,
            SevenSeg_out  => HEX0
        );

    seg1 : BCD_to_SevenSeg
        port map (
            BCD_digit     => Q_sec_tens,
            SevenSeg_out  => HEX1
        );

    seg2 : BCD_to_SevenSeg
        port map (
            BCD_digit     => Q_min_ones,
            SevenSeg_out  => HEX2
        );

    -- Optional flag output (not used yet)
    LEDR(0) <= '0';

end architecture;

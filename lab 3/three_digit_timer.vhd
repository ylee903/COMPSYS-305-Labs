library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity three_digit_timer is
    port (
        Clk       : in  std_logic;
        Reset     : in  std_logic;
        Enable    : in  std_logic;
        Min_ones  : out std_logic_vector(3 downto 0);
        Sec_tens  : out std_logic_vector(3 downto 0);
        Sec_ones  : out std_logic_vector(3 downto 0)
    );
end entity;

architecture structural of three_digit_timer is

    -- Internal signals
    signal s_sec_ones     : std_logic_vector(3 downto 0);
    signal s_sec_tens     : std_logic_vector(3 downto 0);
    signal s_min_ones     : std_logic_vector(3 downto 0);

    signal en_sec_tens    : std_logic := '0';
    signal en_min_ones    : std_logic := '0';
    signal reset_seconds  : std_logic := '0';
    signal reset_timer    : std_logic := '0';

    -- Component declaration
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

    -- Seconds Ones (0–9)
    sec_ones_inst : BCD_Counter
        port map (
            Clk       => Clk,
            Reset     => Reset or reset_seconds or reset_timer,
            Enable    => Enable,
            Direction => '1',
            Q_Out     => s_sec_ones
        );

    -- Enable seconds tens when sec_ones reaches 9 (anticipate at 8)
    process (Clk)
    begin
        if rising_edge(Clk) then
            if Reset = '1' then
                en_sec_tens <= '0';
            elsif Enable = '1' and s_sec_ones = "1000" then
                en_sec_tens <= '1';
            else
                en_sec_tens <= '0';
            end if;
        end if;
    end process;

    -- Seconds Tens (0–5)
    sec_tens_inst : BCD_Counter
        port map (
            Clk       => Clk,
            Reset     => Reset or reset_seconds or reset_timer,
            Enable    => en_sec_tens,
            Direction => '1',
            Q_Out     => s_sec_tens
        );

    -- Enable minutes ones when sec_tens = 5 and sec_ones = 9 (anticipate at 8)
    process (Clk)
    begin
        if rising_edge(Clk) then
            if Reset = '1' then
                en_min_ones <= '0';
            elsif Enable = '1' and s_sec_ones = "1000" and s_sec_tens = "0101" then
                en_min_ones <= '1';
            else
                en_min_ones <= '0';
            end if;
        end if;
    end process;

    -- Reset seconds when 59 is reached (anticipate at 58)
    process (Clk)
    begin
        if rising_edge(Clk) then
            if Reset = '1' then
                reset_seconds <= '0';
            elsif Enable = '1' and s_sec_ones = "1000" and s_sec_tens = "0101" then
                reset_seconds <= '1';
            else
                reset_seconds <= '0';
            end if;
        end if;
    end process;

    -- Reset whole timer when 3:59 is reached (anticipate at 3:58)
    process (Clk)
    begin
        if rising_edge(Clk) then
            if Reset = '1' then
                reset_timer <= '0';
            elsif Enable = '1' and s_sec_ones = "1000"
                             and s_sec_tens = "0101"
                             and s_min_ones = "0011" then
                reset_timer <= '1';
            else
                reset_timer <= '0';
            end if;
        end if;
    end process;

    -- Minutes Ones (0–3)
    min_ones_inst : BCD_Counter
        port map (
            Clk       => Clk,
            Reset     => Reset or reset_timer,
            Enable    => en_min_ones,
            Direction => '1',
            Q_Out     => s_min_ones
        );

    -- Output assignments
    Sec_ones <= s_sec_ones;
    Sec_tens <= s_sec_tens;
    Min_ones <= s_min_ones;

end architecture;

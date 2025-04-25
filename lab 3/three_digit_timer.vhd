-- File: three_digit_timer.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity three_digit_timer is
    port (
        Clk      : in  std_logic;
        Reset    : in  std_logic;
        Enable   : in  std_logic;
        Min_ones : out std_logic_vector(3 downto 0);
        Sec_tens : out std_logic_vector(3 downto 0);
        Sec_ones : out std_logic_vector(3 downto 0)
    );
end three_digit_timer;

architecture structural of three_digit_timer is
    component BCD_Counter
        port (
            Clk       : in  std_logic;
            Reset     : in  std_logic;
            Enable    : in  std_logic;
            Direction : in  std_logic;
            Q_Out     : out std_logic_vector(3 downto 0)
        );
    end component;

    signal s_sec_ones, s_sec_tens, s_min_ones : std_logic_vector(3 downto 0);
    signal carry_sec_ones, carry_sec_tens    : std_logic;
begin
    -- Seconds ones digit (0–9)
    sec_ones_inst : BCD_Counter
        port map(
            Clk       => Clk,
            Reset     => Reset,
            Enable    => Enable,
            Direction => '1',
            Q_Out     => s_sec_ones
        );

    -- Carry from seconds ones when it rolls over from 9 to 0
    carry_sec_ones <= '1' when (s_sec_ones = "1001" and Enable = '1') else '0';

    -- Seconds tens digit (0–5)
    sec_tens_inst : BCD_Counter
        port map(
            Clk       => Clk,
            Reset     => Reset,
            Enable    => carry_sec_ones,
            Direction => '1',
            Q_Out     => s_sec_tens
        );

    -- Carry from seconds tens when it rolls over from 5 to 0
    carry_sec_tens <= '1' when (s_sec_tens = "0101" and carry_sec_ones = '1') else '0';

    -- Minutes ones digit (0–3)
    min_ones_inst : BCD_Counter
        port map(
            Clk       => Clk,
            Reset     => Reset,
            Enable    => carry_sec_tens,
            Direction => '1',
            Q_Out     => s_min_ones
        );

    -- Output assignments
    Sec_ones <= s_sec_ones;
    Sec_tens <= s_sec_tens;
    Min_ones <= s_min_ones;
end structural;
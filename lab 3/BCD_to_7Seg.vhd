-- Morteza (March 2023)
-- VHDL code for BCD to 7-Segment conversion
-- Important Note: This design assumes common-anode display,
-- where an LED segment lights up when its control bit is '0'

-- Include the IEEE standard library for basic logic types
LIBRARY IEEE;
-- Use the standard logic definitions (std_logic and std_logic_vector)
USE IEEE.std_logic_1164.ALL;

-- === Entity Declaration ===
-- The entity is named BCD_to_SevenSeg
-- It takes a 4-bit BCD input and outputs a 7-bit signal to drive a 7-segment display
ENTITY BCD_to_SevenSeg IS
	PORT (
		BCD_digit : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit input representing a BCD digit (0–9)
		SevenSeg_out : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- 7-bit output for segments a–g
	);
END ENTITY;

-- === Architecture Definition ===
-- Architecture name is 'arc1'
-- Uses a conditional assignment to map each BCD digit to its corresponding 7-segment pattern
ARCHITECTURE arc1 OF BCD_to_SevenSeg IS
BEGIN
	-- Assign the output pattern based on the BCD input
	-- Each pattern represents the segments [a b c d e f g]
	-- A '0' means the LED is ON (because it's a common-anode display)

	SevenSeg_out <=
		"1111001" WHEN BCD_digit = "0001" ELSE -- Displays digit 1 (segments b and c ON)
		"0100100" WHEN BCD_digit = "0010" ELSE -- Displays digit 2
		"0110000" WHEN BCD_digit = "0011" ELSE -- Displays digit 3
		"0011001" WHEN BCD_digit = "0100" ELSE -- Displays digit 4
		"0010010" WHEN BCD_digit = "0101" ELSE -- Displays digit 5
		"0000010" WHEN BCD_digit = "0110" ELSE -- Displays digit 6
		"1111000" WHEN BCD_digit = "0111" ELSE -- Displays digit 7
		"0000000" WHEN BCD_digit = "1000" ELSE -- Displays digit 8 (all segments ON)
		"0010000" WHEN BCD_digit = "1001" ELSE -- Displays digit 9
		"1000000" WHEN BCD_digit = "0000" ELSE -- Displays digit 0
		"1111111"; -- Default: all segments OFF (blank display)
END ARCHITECTURE arc1;
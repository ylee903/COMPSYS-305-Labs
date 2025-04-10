LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY two_digit_counter IS --ENTITY means "the name of this black box is two_digit_counter" 
    --is means the start of an enity delcaration "this is what it is" or "this is what ports it has (when used on ENTITY)"
    PORT (
        Clk : IN STD_LOGIC; --STD_LOGIC used instead of BIT because it can represent more states
        Reset : IN STD_LOGIC;
        Enable : IN STD_LOGIC;
        Q_Tens : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- create array with indexes where 3 is the first and 0 is last, without directly stating,
        -- we have 4 bits because of this."
        Q_Ones : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE structural OF two_digit_counter IS --The line ARCHITECTURE structural of two_digit_counter is declares an architecture named 
    --structural that provides the structural implementation of the two_digit_counter entity. It typically involves instantiating
    --and connecting subcomponents to build the overall design.

    -- Internal signals to connect subcomponents
    SIGNAL Ones_Q : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL Tens_Q : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL Tens_En : STD_LOGIC := '0'; -- Enable signal for tens digit counter, basicly, the carry over signal

    COMPONENT BCD_Counter -- COMPONENT BCD_Counter means there is another VHDL file (or module) with an ENTITY named BCD_Counter 
        --that has the following:
        PORT (
            Clk : IN STD_LOGIC;
            Reset : IN STD_LOGIC;
            Enable : IN STD_LOGIC;
            Direction : IN STD_LOGIC;
            Q_Out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;
BEGIN -- The BEGIN keyword is required by VHDL to separate the declarative section (optional) from the executable section.
    -- You can declare variables between PROCESS and BEGIN, but not SIGNALS.
    -- Variables declared here are local to this process and only exist during its execution.
    -- Ones digit counter (always counts up)
    ones_digit : BCD_Counter --create an instance of the "BCD_Counter" module and name it "ones_digit", it inheriits it's sensitivity list from the BCD_Counter module
    PORT MAP(
        Clk => Clk, -- connect the Clk port of the "ones_digit" instance to the Clk port of the "two_digit_counter" entity
        Reset => Reset, -- connect the Reset port of the "ones_digit" instance to the Reset port of the "two_digit_counter" entity
        Enable => Enable, -- connect the Enable port of the "ones_digit" instance to the Enable port of the "two_digit_counter" entity
        Direction => '1', -- set the Direction port of the "ones_digit" instance to '1' (count up)
        Q_Out => Ones_Q -- connect the Q_Out port of the "ones_digit" instance to the Ones_Q signal
    );

    -- Tens digit counter (counts up only when Ones rolls over)
    tens_digit : BCD_Counter --create an instance of the "BCD_Counter" module and name it "tens_digit", it inheriits it's sensitivity list from the BCD_Counter module
    PORT MAP(
        Clk => Clk, -- connect the Clk port of the "tens_digit" instance to the Clk port of the "two_digit_counter" entity
        Reset => Reset, -- connect the Reset port of the "tens_digit" instance to the Reset port of the "two_digit_counter" entity
        Enable => Tens_En, -- connect the Enable port of the "tens_digit" instance to the Tens_En signal
        Direction => '1', -- set the Direction port of the "tens_digit" instance to '1' (count up)
        Q_Out => Tens_Q -- connect the Q_Out port of the "tens_digit" instance to the Tens_Q signal
    );

    -- 
    -- Generate enable signal for tens digit when ones rolls from 9 → 0 (but this actually works on when the e1's is 8, lol)
    PROCESS (Clk) -- This process is sensitive to changes in Clk. It will execute whenever Clk changes.
    BEGIN
        IF rising_edge(Clk) THEN -- Check for rising edge of Clk
            IF Reset = '1' THEN -- change the carry (Tens_En) to 0 if reset is 1
                Tens_En <= '0';

            ELSIF Enable = '1' AND Ones_Q = "1000" THEN -- when Enable is 1 and Ones_Q is decimal 8 (this check is done on the same clock edge as the ones's digit BECOMES 8, or on the clock edge when 7->8), do the following
                Tens_En <= '1'; -- Enable the carry, set Tens_En to 1 on the next clock cycle (this mean on the clock edge where 8->9!!!!)
            ELSE
                Tens_En <= '0'; -- Default
            END IF;
        END IF;
    END PROCESS;

    -- Assign outputs
    Q_Tens <= Tens_Q;
    Q_Ones <= Ones_Q;
END ARCHITECTURE;
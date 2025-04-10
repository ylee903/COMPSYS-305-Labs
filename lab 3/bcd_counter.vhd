LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY BCD_Counter IS --ENTITY means "the name of this black box is BCD_Counter" is means the start of an enity delcaration "this is what it is" or "this is what ports it has (when used on ENTITY)"
    PORT (
        Clk : IN STD_LOGIC; --STD_LOGIC used instead of BIT because it can represent more states
        Reset : IN STD_LOGIC;
        Enable : IN STD_LOGIC;
        Direction : IN STD_LOGIC;
        Q_Out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY BCD_Counter;

ARCHITECTURE behavior OF BCD_Counter IS --ARCHITECTURE means "this is how it works" or "this is how it is implemented", behavior is the name of this architecture of the entity named "BCD_Counter"
    SIGNAL counter : unsigned(3 DOWNTO 0) := "0000"; -- 4-bit for BCD 0 to 9. 
    -- In VHDL, signals are not updated immediately when assigned a new value.
    -- Instead, the new value is scheduled to take effect at the end of the current simulation delta cycle.
    -- A "delta cycle" is a zero-time step used by the simulator to resolve signal updates and dependencies
    -- within the same simulation time. This means that within the same process execution, any read of the signal
    -- will return its current value, not the newly assigned value. The updated value will only be visible
    -- after the delta cycle completes.
    -- Within the same "PROCESS" block:
    -- - When a signal is assigned a new value, the update is scheduled to take effect after the current simulation delta cycle.
    -- - Any read of the signal within the same process execution will return its old value, not the newly assigned value.
    -- - The updated value will only be visible in the next process execution (e.g., on the next rising clock edge if the process is clocked).

    -- Across different "PROCESS" blocks:
    -- - If a signal is updated in one process, its updated value will be visible to other processes after the current simulation delta cycle completes.
    -- - This means that other processes will see the updated value of the signal in the same simulation time step, but only after the first process has finished executing.
BEGIN --BEGIN marks the start of the architecture implementation, seperating it from the entity declaration (what variables or ports it has or signals it uses)
    PROCESS (Clk) -- This process is sensitive to changes in Clk. It will execute whenever Clk changes.
    BEGIN -- The BEGIN keyword is required by VHDL to separate the declarative section (optional) from the executable section.
        -- You can declare variables between PROCESS and BEGIN, but not SIGNALS.
        -- Variables declared here are local to this process and only exist during its execution.
        IF rising_edge(Clk) THEN
            IF Reset = '1' THEN
                -- Perform reset regardless of Enable
                IF Direction = '1' THEN
                    counter <= "0000"; -- reset to 0 if counting up
                ELSE
                    counter <= "1001"; -- reset to 9 if counting down assuming Direction is 0
                END IF;

            ELSIF Enable = '1' THEN
                -- Normal counting
                IF Direction = '1' THEN
                    -- Count up
                    IF counter = "1001" THEN
                        counter <= "0000";
                    ELSE
                        counter <= counter + 1;
                    END IF;
                ELSE
                    -- Count down
                    IF counter = "0000" THEN
                        counter <= "1001";
                    ELSE
                        counter <= counter - 1;
                    END IF;
                END IF;
            END IF;
            -- No action if Enable = '0'
        END IF;
    END PROCESS;
    -- Output assignment
    Q_Out <= STD_LOGIC_VECTOR(counter);
    -- Explanation:
    -- The assignment `Q_Out <= STD_LOGIC_VECTOR(counter);` is necessary because of type compatibility in VHDL.
    --   - `counter` was  declared as an `unsigned` type (e.g., `unsigned(3 DOWNTO 0)`) back in SIGNAL counter : unsigned(3 DOWNTO 0) := "0000";.
    --   - `Q_Out` is declared as a `STD_LOGIC_VECTOR` type (e.g., `Q_Out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)`).
    -- 
    -- Although both `unsigned` and `STD_LOGIC_VECTOR` are 4-bit wide vectors in this case, they are treated as 
    -- distinct and incompatible types in VHDL. VHDL enforces strict type checking, meaning you cannot directly 
    -- assign an `unsigned` type to a `STD_LOGIC_VECTOR` type without explicitly converting it.
    --
    -- The function `STD_LOGIC_VECTOR(counter)` is used to perform this type conversion. It converts the `unsigned` 
    -- value of `counter` into a `STD_LOGIC_VECTOR` value, which can then be assigned to `Q_Out`.
    -- Why can't we use `Q_Out <= counter;` directly?
    --   - If you try to assign `counter` directly to `Q_Out` (i.e., `Q_Out <= counter;`), the VHDL compiler will 
    --     throw a type mismatch error because `unsigned` and `STD_LOGIC_VECTOR` are different types.
    --   - The explicit conversion using `STD_LOGIC_VECTOR(counter)` resolves this type mismatch and ensures that 
    --     the assignment is valid.
END ARCHITECTURE behavior;
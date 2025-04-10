LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY test_two_digit_counter IS -- ENTITY means "the name of this black box is test_two_digit_counter"
END ENTITY; -- The ENTITY of the testbench is empty because the testbench is self-contained and does not need to interact with the outside world.
--Instead of ports, signals are declared in the testbench to connect to the UUT's ports.
--The UUT (two_digit_counter) defines the actual input and output ports, which are connected to the testbench signals using the PORT MAP statement.

ARCHITECTURE tb OF test_two_digit_counter IS --declares an architecture named tb for the entity test_two_digit_counter.
    --This architecture will define the internal structure or behavior of the test_two_digit_counter entity.
    -- Signals for the UUT (unit under test)
    SIGNAL Clk : STD_LOGIC := '0';
    SIGNAL Reset : STD_LOGIC := '0';
    SIGNAL Enable : STD_LOGIC := '1';
    SIGNAL Q_Tens : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL Q_Ones : STD_LOGIC_VECTOR(3 DOWNTO 0);

    COMPONENT two_digit_counter
        PORT (
            Clk : IN STD_LOGIC;
            Reset : IN STD_LOGIC;
            Enable : IN STD_LOGIC;
            Q_Tens : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            Q_Ones : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;
BEGIN
    uut : two_digit_counter -- create an instance of the "two_digit_counter" module and name it "uut", "uut" is short for "unit under test"
    PORT MAP(
        Clk => Clk, -- connect the Clk port of the "uut" instance to the Clk signal
        Reset => Reset, -- connect the Reset port of the "uut" instance to the Reset signal
        Enable => Enable, -- connect the Enable port of the "uut" instance to the Enable signal
        Q_Tens => Q_Tens, -- connect the Q_Tens port of the "uut" instance to the Q_Tens signal
        Q_Ones => Q_Ones -- connect the Q_Ones port of the "uut" instance to the Q_Ones signal
    );

    -- Clock generation: 100 MHz = 10 ns period
    clock_gen : PROCESS -- create a process named "clock_gen" to generate the clock signal, this process will run continuously, forever.
    BEGIN
        Clk <= '0';
        WAIT FOR 5 ns;
        Clk <= '1';
        WAIT FOR 5 ns;
    END PROCESS;
    -- Periodic reset every 1500 ns (reset lasts 20 ns)
    periodic_reset : PROCESS
    BEGIN
        WAIT FOR 1480 ns; -- to maintain total period of 1500 ns
        Reset <= '1';
        WAIT FOR 20 ns;
        Reset <= '0';
    END PROCESS;

    --Try pausing every 600 ns (lasts 50 ns)
    pause : PROCESS
    BEGIN
        WAIT FOR 600 ns;
        Enable <= '0';
        WAIT FOR 50 ns;
        Enable <= '1';
        WAIT FOR 850 ns;
        --Enable <= '1'; --no need to re-enable, as it is already enabled
    END PROCESS;

END ARCHITECTURE;
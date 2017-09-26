    ----------------------------------------------------------------------------
--
--  FIR Filter Block
--
--  This is the entity declaration for the customizable FIR filter block.
--
--  Revision History:
--     2017-05-20   Torkom P.   Initial Revision
--	   2017-05-25	Torkom P. 	Changed the form from a symetric form to a
--								standard form filter
--	   2017-06-25 	Torkom P. 	Added comments
--
----------------------------------------------------------------------------

--
--  FIR Filter
--
--  The filter is implementing a FIR filter using a series of FIR filter elements
--	each with their own coefficients.  The filter has synchronizer blocks to 
--	synchronize the async signals from the SPI peripheral deserializer, a a shift
--	register to shift in a new value when it becomes available.  The filter
--	coefficients are placed in an array and are assigned in a for-generate loop
--	which prodices each of the FIR filter entities
--

--  Inputs:
--	dataIn - Asynchronous data from the SPI interface
--	dataRdy - Asynchronous data ready signal from the SPI interface
--	sysclk - System clock 
--	RESET - Global Reset signal

--  Outputs:
--    dataOut   - Filtered output of the filter 
--  

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

----------------------------------------------------------------------------------
-- The synchronizer16 block takes in a standard logic vector which is 16-bits wide
-- and a system clock and produces a 16-bit standard logic vector which is
-- synchronized to the system clock. It is done by passing the signal through 
-- two DFFs which are clocked by the system clock
----------------------------------------------------------------------------------

entity synchronizer16 is
    Port (  
        dataIn  : in std_logic_vector (15 downto 0);    -- Data input from asynchronous source
        dataOut : out std_logic_vector (15 downto 0);   -- Synchronized output 
        sysclk  : in std_logic                          -- Synchronization clock
        );
end synchronizer16;

architecture synchronizer16_arch of synchronizer16 is
	signal stage1 : std_logic_vector (15 downto 0); -- Temporary intermediate signal 
begin
	
	process(sysclk)
	begin
		
		-- Pass the signal through two DFFs which are clocked by the system clock
		if (rising_edge(sysclk)) then
			stage1 <= dataIn;
			dataOut <= stage1;
		end if;
	end process;
	
end synchronizer16_arch;

----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

----------------------------------------------------------------------------------
-- The synchronizer block takes in a standard logic type and a system clock and 
-- produces a standard logic type signal which is synchronized to the system 
-- clock. It is done by passing the signal through two DFFs which are clocked 
-- by the system clock
----------------------------------------------------------------------------------

entity synchronizer is
    Port (  
        dataIn  : in std_logic;     -- Data input from asynchronous source
        dataOut : out std_logic;    -- Synchronized output 
        sysclk  : in std_logic    	-- Synchronization clock 
        );
end synchronizer;

architecture synchronizer_arch of synchronizer is
	signal stage1 : std_logic; -- Temporary intermediate signal 
begin
	
	process(sysclk)
	begin
		-- Pass the signal through two DFFs which are clocked by the system clock
		if (rising_edge(sysclk)) then
            -- Move the data through two DFFs using the system clock to synchronize 
			stage1 <= dataIn;
			dataOut <= stage1;
		end if;
	end process;
	
end synchronizer_arch;

----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;


entity fir is
    Port ( 
        dataIn : in std_logic_vector (15 downto 0); -- Asynchronous data from the SPI interface
        dataRdy : in std_logic;                     -- Asynchronous data ready signal from the SPI interface
        sysclk : in std_logic;                      -- System clock 
        RESET : in std_logic;						-- Global Reset signal
        
        dataOut : out signed (17 downto 0) -- Filter Output 
        ); 
end fir;

architecture fir_arch of fir is
	component synchronizer16 is
	    Port (  
	        dataIn  : in std_logic_vector (15 downto 0);    -- Data input from asynchronous source
	        dataOut : out std_logic_vector (15 downto 0);   -- Synchronized output 
	        sysclk  : in std_logic                          -- Synchronization clock
	    );
	end component;
	
	component synchronizer is
	    Port (  
	        dataIn  : in std_logic;     -- Data input from asynchronous source
	        dataOut : out std_logic;    -- Synchronized output 
	        sysclk  : in std_logic      -- Synchronization clock 
	    );
	end component;
	
	component firElement is
		Generic(
			coeff : signed(15 downto 0)
			);
	    Port ( 
	        A : in signed(15 downto 0); 	-- Signed 16-bit asynchronous data from the ADC's SPI interface
			PIN	: in signed(33 downto 0);	-- Accumulator input from previous element
			RESET : in std_logic;					-- Global reset signal
			
			POUT : out signed(33 downto 0) -- Accumulator output into the next block
	        ); 
	end component;
	
	
	-- Signal Declarations  
	signal dataIn_synced : std_logic_vector(15 downto 0);   -- ADC data synchronized to system clock 
	signal dataRdy_synced : std_logic; 
	
	-- The shift register for the input data for the filter
	type INPUT_ARRAY is array (127 downto 0) of signed(15 downto 0);
	
	signal inputData : INPUT_ARRAY := (others => (others => '0'));  
	

	-- Accumulator output array to hold the accumulator signals which pass
	-- through each filter element
	type ACCUMULATOR_OUTPUTS is array (127 downto 0) of signed(33 downto 0);
	
	signal accumulatorOutputs : ACCUMULATOR_OUTPUTS :=  (others => (others => '0'));
	
	-- Filter coefficient array holds the coefficients for each filter element
	type COEF_TYPE is array (127 downto 0) of signed(15 downto 0);
    
    constant firCoef : COEF_TYPE := (	X"ffaa",X"ffe7",X"ffe4",X"ffe1",X"ffdd",
										X"ffda",X"ffd7",X"ffd4",X"ffd2",X"ffcf",X"ffcd",
										X"ffcc",X"ffcb",X"ffcb",X"ffcb",X"ffcc",X"ffce",
										X"ffd1",X"ffd5",X"ffda",X"ffe0",X"ffe7",X"fff0",
										X"fffa",X"0005",X"0011",X"001f",X"002e",X"003f",
										X"0051",X"0065",X"0079",X"0090",X"00a7",X"00bf",
										X"00d9",X"00f4",X"010f",X"012c",X"0149",X"0166",
										X"0184",X"01a3",X"01c1",X"01df",X"01fe",X"021c",
										X"0239",X"0256",X"0272",X"028c",X"02a6",X"02be",
										X"02d5",X"02eb",X"02fe",X"0310",X"0320",X"032d",
										X"0339",X"0342",X"0349",X"034e",X"0351",X"0351",
										X"034e",X"0349",X"0342",X"0339",X"032d",X"0320",
										X"0310",X"02fe",X"02eb",X"02d5",X"02be",X"02a6",
										X"028c",X"0272",X"0256",X"0239",X"021c",X"01fe",
										X"01df",X"01c1",X"01a3",X"0184",X"0166",X"0149",
										X"012c",X"010f",X"00f4",X"00d9",X"00bf",X"00a7",
										X"0090",X"0079",X"0065",X"0051",X"003f",X"002e",
										X"001f",X"0011",X"0005",X"fffa",X"fff0",X"ffe7",
										X"ffe0",X"ffda",X"ffd5",X"ffd1",X"ffce",X"ffcc",
										X"ffcb",X"ffcb",X"ffcb",X"ffcc",X"ffcd",X"ffcf",
										X"ffd2",X"ffd4",X"ffd7",X"ffda",X"ffdd",X"ffe1",
										X"ffe4",X"ffe7",X"ffaa");
											
	constant PIN_ZERO : signed(33 downto 0) := (others => '0');
	
begin
	
	-- Synchronize data with the system clock from the async SPI interface
	dataIn_Sync : synchronizer16
	port map(
		dataIn => dataIn,
		dataOut => dataIn_synced,
		sysclk => sysclk
	);
	
    -- Synchronize the data ready signal so the filter knows when to latch data 
	dataRdy_Sync : synchronizer
	port map(
		dataIn => dataRdy,
		dataOut => dataRdy_synced,
		sysclk => sysclk
	);
	
	-- Shift Register for input data
	process (dataRdy_synced)
	begin
		
		-- When data is valid, shift it into the filter one element at a time
		if (rising_edge(dataRdy_synced)) then
			
			-- Shift register is using the synchronized data signals
			inputData(0) <= signed(dataIn_Synced);
			inputData(127 downto 1) <= inputData(126 downto 0);
			
		end if;  
		
	end process;
	
	
	-- For Generage loop for creating the filter elements
	makeFilter: for element in 1 to firCoef'LENGTH generate
		begin
			-- The first element does not have a previous element so the PCIN value is 0
			FirstElement: if (element = 1) generate
				InitialElement: firElement 
					generic map (coeff => firCoef(0)) -- Filter coefficient
					port map (
						A => inputData(0), -- input signal
						PIN	=> PIN_ZERO, -- previous accumulator output
						RESET => RESET, 
						POUT => accumulatorOutputs(0) -- accumulator output of current cell
					);
			end generate FirstElement;
			
			-- The remaining elements are cascaded
			RemainingElements: if (element /= 1) generate
				FIR_Element: firElement 
					generic map (coeff => firCoef(element -1)) -- Filter coefficient
					port map (
						A => inputData(element - 1), -- input signal
						PIN	=> accumulatorOutputs(element - 2), -- previous accumulator output
						RESET => RESET,
						POUT => accumulatorOutputs(element - 1));  -- accumulator output of current cell 															-- Output
			end generate RemainingElements;
			
	end generate makeFilter;
	
	-- Truncating the accumulator output to match the filter output data length (18 bits)
	dataOut <= accumulatorOutputs(127)(32 downto 15);

end fir_arch;

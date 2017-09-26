    ----------------------------------------------------------------------------
--
--  FIR Element
--
--  This is the entity declaration for a single FIR filter element
--
--  Revision History:
--     2017-05-22   Torkom P.   Initial Revision
--	   2017-05-25	Torkom P. 	Switched IP multipliers and adders for ones
--								synthesized by the '+' and '*' operators
--
----------------------------------------------------------------------------

--
--  FIR Element
--
--  The file is implementing a singla FIR filter element.  The element consists
--	of a multiplier and accumulator.  The multiplier is multiplying a input
--	signal by the filter's coefficient.  The result of the multiplication is
--	then added to the result of the previous filter element
--

-- 	Generic:
--		coeff - Filter coefficient

--  Inputs:
--		A - Signed 16-bit asynchronous data from the ADC's SPI interface 
--		PIN	- Accumulator input from previous element
--		RESET - Global reset signal
		
--  Outputs:
--    	POUT - Accumulator output into the next block
--  

----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity firElement is
	Generic(
		coeff : signed(15 downto 0) -- filter coefficient
	);
    Port ( 
        A : in signed(15 downto 0); 	-- Signed 16-bit asynchronous data from the ADC's SPI interface 
		PIN	: in signed(33 downto 0);	-- Accumulator input from previous element
		RESET : in std_logic;					-- Global reset signal
		
		POUT : out signed(33 downto 0) -- Accumulator output into the next block
        ); 
end firElement;

architecture firElement_arch of firElement is
    
    signal multOut	   : signed(31 downto 0);	-- intermediate signal for the output of the multiplier

begin
	
	-- Input signal is multiplied by the coefficient
	multOut <= A * coeff;

	-- Result of multiplication is added to result from the previous element
	POUT <= PIN + multOut;
	
end firElement_arch;

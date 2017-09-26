    ----------------------------------------------------------------------------
--
--  Digital Filter
--
--  This is the four channel filter entity for the system
--
--  Revision History:
--     2017-06-01   Torkom P.   Initial Revision
--
----------------------------------------------------------------------------

--
--  Filter
--
--  The filter is a wrapper for the individual channel filters.  It splits up 
--	the signals from the SPI peripheral into the various filter blocks.
--

--  Inputs:
--	cha_dataIn  - 16bit data from ADC Channel A
--  chb_dataIn  - 16bit data from ADC Channel B
--  chc_dataIn  - 16bit data from ADC Channel C 
--  chd_dataIn  - 16bit data from ADC Channel D
--  dataRdy 	- Asynchronous data ready signal from the SPI interface
    
--  sysclk 		- System clock 
    
--  RESET		- Global Reset signal

--	Outputs:    
--	cha_dataOut - 16bit filtered data for ADC Channel A
--	chb_dataOut - 16bit filtered data for ADC Channel B
--	chc_dataOut - 16bit filtered data for ADC Channel C
--	chd_dataOut - 16bit filtered data for ADC Channel D
--  

----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity filter is
    Port ( 
        cha_dataIn  : in   	std_logic_vector(15 downto 0); -- 16bit data from ADC Channel A
        chb_dataIn  : in   	std_logic_vector(15 downto 0); -- 16bit data from ADC Channel B
        chc_dataIn  : in   	std_logic_vector(15 downto 0); -- 16bit data from ADC Channel C 
        chd_dataIn  : in   	std_logic_vector(15 downto 0); -- 16bit data from ADC Channel D
        dataRdy 	: in 	std_logic;                     -- Asynchronous data ready signal from the SPI interface
        
        sysclk 		: in 	std_logic;                     -- System clock 
        
        RESET		: in 	std_logic;					   -- Global Reset signal
        
        cha_dataOut : out   signed(17 downto 0); -- 16bit filtered data for ADC Channel A
        chb_dataOut : out   signed(17 downto 0); -- 16bit filtered data for ADC Channel B
        chc_dataOut : out   signed(17 downto 0); -- 16bit filtered data for ADC Channel C
        chd_dataOut : out   signed(17 downto 0) -- 16bit filtered data for ADC Channel D
        
        ); 
end filter;

architecture filter_arch of filter is

	-- FIR filter
	component fir is
	    Port ( 
	        dataIn : in std_logic_vector (15 downto 0); -- Asynchronous data from the SPI interface
	        dataRdy : in std_logic;                     -- Asynchronous data ready signal from the SPI interface
	        sysclk : in std_logic;                      -- System clock 
	        RESET : in std_logic;						-- Global Reset signal
	        
	        dataOut : out signed (17 downto 0) -- Filter Output 
	        ); 
	end component;

    
begin
	
	FIR_chA : fir
	PORT MAP(
		dataIn => cha_dataIn,
		dataRdy => dataRdy,
		sysclk => sysclk,
		RESET  => RESET,
		dataOut => cha_dataOut
	);
	
	FIR_chB : fir
	PORT MAP(
		dataIn => chb_dataIn,
		dataRdy => dataRdy,
		sysclk => sysclk,
		RESET  => RESET,
		dataOut => chb_dataOut
	);
	
	FIR_chC : fir
	PORT MAP(
		dataIn => chc_dataIn,
		dataRdy => dataRdy,
		sysclk => sysclk,
		RESET  => RESET,
		dataOut => chc_dataOut
	);
	
	FIR_chD : fir
	PORT MAP(
		dataIn => chd_dataIn,
		dataRdy => dataRdy,
		sysclk => sysclk,
		RESET  => RESET,
		dataOut => chd_dataOut
	);


end filter_arch;

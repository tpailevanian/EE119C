    ----------------------------------------------------------------------------
--
--  Transducer Array Top System HDL
--
--  This is the entity declaration for the Transducer Array System.
--
--  Revision History:
--     2017-06-10   Torkom P.   Initial Revision
--
----------------------------------------------------------------------------

--
--  Transducer Array
--
--  The top level system architecture connects the signals to the various 
-- 	system blocks.  The input signals from the ADC are tied to the ADC block 
--	and the control signals from the SPI block are routed out of the system.
--	the input signals from the SPI block are routed to the filter block and
--	the result from the filter block is routed out of the system
--

--  Inputs:
--		sysclk      : in    std_logic; -- system clock into the spi block

--		sdoa        : in    std_logic; 			-- SPI data line for ADC Channel A
--		sdob        : in    std_logic; 			-- SPI data line for ADC Channel B
--		sdoc        : in    std_logic; 			-- SPI data line for ADC Channel C
--		sdod        : in    std_logic; 			-- SPI data line for ADC Channel D
--		sck_in      : in    std_logic; 			-- Phase adjusted SCK signal from ADC
--		RESET		: in 	std_logic;			-- Global Reset signal

--  Outputs:
--		conv 		: out   std_logic := '0'; 	-- Trigger for ADC to sample
--		sck_out     : out   std_logic := '0'; -- SPI Clock output to the ADC   
--		cha_dataOut : out   signed(17 downto 0); -- 16bit filtered data for ADC Channel A
--		chb_dataOut : out   signed(17 downto 0); -- 16bit filtered data for ADC Channel B
--		chc_dataOut : out   signed(17 downto 0); -- 16bit filtered data for ADC Channel C
--		chd_dataOut : out   signed(17 downto 0) -- 16bit filtered data for ADC Channel D
--  

----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity system is
    Port ( 
	sysclk      : in    std_logic; -- system clock into the spi block

	sdoa        : in    std_logic; 			-- SPI data line for ADC Channel A
	sdob        : in    std_logic; 			-- SPI data line for ADC Channel B
	sdoc        : in    std_logic; 			-- SPI data line for ADC Channel C
	sdod        : in    std_logic; 			-- SPI data line for ADC Channel D
	sck_in      : in    std_logic; 			-- Phase adjusted SCK signal from ADC
	
	conv 		: out   std_logic := '0'; 	-- Trigger for ADC to sample
	sck_out     : out   std_logic := '0'; -- SPI Clock output to the ADC
	
	RESET		: in 	std_logic;			-- Global Reset signal
        
    cha_dataOut : out   signed(17 downto 0); -- 16bit filtered data for ADC Channel A
    chb_dataOut : out   signed(17 downto 0); -- 16bit filtered data for ADC Channel B
    chc_dataOut : out   signed(17 downto 0); -- 16bit filtered data for ADC Channel C
    chd_dataOut : out   signed(17 downto 0) -- 16bit filtered data for ADC Channel D
        
        ); 
end system;

architecture system_arch of system is

	-- SPI Peripheral
	component spi is
	port (
			
	      sysclk      : in    std_logic; -- system clock into the spi block
	        
	      sdoa        : in    std_logic; -- SPI data line for ADC Channel A
	      sdob        : in    std_logic; -- SPI data line for ADC Channel B
	      sdoc        : in    std_logic; -- SPI data line for ADC Channel C
	      sdod        : in    std_logic; -- SPI data line for ADC Channel D
	      sck_in      : in    std_logic; -- Phase adjusted SCK signal from ADC
			
		  conv 		  : out   std_logic := '0'; -- Trigger for ADC to sample
		  
		  RESET		  : in 	std_logic;			-- Global Reset signal
			
	      sck_out     : out   std_logic := '0'; -- SPI Clock output to the ADC
		  cha_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel A
		  chb_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel B
		  chc_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel C
		  chd_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel D
			
		  data_rdy    : buffer   std_logic := '0' -- Flag set by SPI block when data is ready to be read
	    );
	
	end component;
	
	-- Digital Filter
	component filter is
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
	end component;

	signal dataA, dataB, dataC, dataD : std_logic_vector(15 downto 0);
	signal data_rdy : std_logic;
    
begin
	
	SPI_Peripheral : spi
	PORT MAP(
		sysclk => sysclk,
		        
	    sdoa => sdoa,
	    sdob => sdob,
	    sdoc => sdoc,
	    sdod => sdod,
	    sck_in => sck_in,
			
		conv => conv,
		sck_out => sck_out,
		
		RESET => RESET,
			    
		cha_data => dataA,
		chb_data => dataB,
		chc_data => dataC,
		chd_data => dataD,
		data_rdy => data_rdy
	);
	
	FIR_Filter : filter
	PORT MAP(
		cha_dataIn  => dataA,
        chb_dataIn  => dataB,
        chc_dataIn  => dataC,
        chd_dataIn  => dataD,
        dataRdy 	=> data_rdy,
        
        sysclk 		=> sysclk,
        
        RESET		=> RESET,
        
        cha_dataOut => cha_dataOut,
        chb_dataOut => chb_dataOut,
        chc_dataOut => chc_dataOut,
        chd_dataOut => chd_dataOut
		
	);
	

end system_arch;

----------------------------------------------------------------------------
--
--  SPI Interface Test Bed
--
--  This is the test bench for the ADC SPI Interface.
--
--	This test bench checks the ADC conversion controls and timing.  It sends
--	data to the SPI block one bit at a time and checks the output of the 
--	deserializer to make sure that it is properly converting the serial
-- 	SPI data to a standard logic vector.
--
--  Revision History:
--     2017-05-05   Torkom P.   Initial Revision
--	   2017-06-12   Torkom P.	Added assert statements for data
--								Added default values for signals
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

use std.textio.all;

entity spi_tb is
end spi_tb;

architecture spi_tb_arch of spi_tb is
 
    component spi is
    port (
		
        sysclk      : in    std_logic; -- system clock into the spi block
        
			sdoa        : in    std_logic; -- SPI data line for ADC Channel A
			sdob        : in    std_logic; -- SPI data line for ADC Channel B
			sdoc        : in    std_logic; -- SPI data line for ADC Channel C
			sdod        : in    std_logic; -- SPI data line for ADC Channel D
			sck_in      : in    std_logic; -- Phase adjusted SCK signal from ADC
		 
			conv			: out   std_logic := '0'; -- Trigger for ADC to sample
			sck_out     : out   std_logic; -- SPI Clock output to the ADC
			cha_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel A
			chb_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel B
			chc_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel C
			chd_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel D
		
			data_rdy    : buffer   std_logic -- Flag set by SPI block when data is ready to be read
    );

    end component;

    signal clock       : std_logic; -- system clock into the spi block
        
    signal sdoa        : std_logic := '0'; -- SPI data line for ADC Channel A
    signal sdob        : std_logic := '0'; -- SPI data line for ADC Channel B
    signal sdoc        : std_logic := '0'; -- SPI data line for ADC Channel C
    signal sdod        : std_logic := '0'; -- SPI data line for ADC Channel D
    signal sck_in      : std_logic := '0'; -- Phase adjusted SCK signal from ADC
		
	signal sck_out     : std_logic := '0'; -- SPI Clock output to the ADC
	signal cha_data    : std_logic_vector(15 downto 0); -- 16bit data from ADC Channel A
	signal chb_data    : std_logic_vector(15 downto 0); -- 16bit data from ADC Channel B
	signal chc_data    : std_logic_vector(15 downto 0); -- 16bit data from ADC Channel C
	signal chd_data    : std_logic_vector(15 downto 0); -- 16bit data from ADC Channel D
    
    signal data_rdy    : std_logic; -- Flag set by SPI block when data is ready to be read
	 
	signal conv 		  : std_logic := '0';  -- Trigger for ADC to sample
	 

	-- Array to store sample ADC output data for testing 
	type SPI_Data is array (3 downto 0) of std_logic_vector(15 downto 0);
	 
	signal cha : SPI_Data := ("1010101010101010", "0000111100001111", "1001011001101001", "1110010100110101");
	signal chb : SPI_Data := ("1110010100110101","1010101010101010", "0000111100001111", "1001011001101001" );
	signal chc : SPI_Data := ("1001011001101001", "1110010100110101","1010101010101010", "0000111100001111" );
	signal chd : SPI_Data := ("0000111100001111", "1001011001101001", "1110010100110101","1010101010101010" );

    signal END_SIM : BOOLEAN := FALSE;


begin
  UUT : spi
    port map (
      sysclk => clock,
      sdoa => sdoa,
      sdob => sdob,
      sdoc => sdoc,
      sdod => sdod,
      sck_in => sck_in,
		
	  conv => conv,
      sck_out => sck_out,
      cha_data => cha_data,
	  chb_data => chb_data,
	  chc_data => chc_data,
	  chd_data => chd_data,
		
	   data_rdy => data_rdy
    );


  process

  begin
 
		wait for 1.25 ns;
		
		wait for 6 ns;
		
		-- Make sure the convert signal is active
		assert(conv = '1')    
          report  "should be sampling now"
          severity  ERROR;
		
		wait for 25 ns;
		
		-- Make sure the convert signal is inactive 
		assert(conv = '0')    
          report  "Should be done sampling"
          severity  ERROR;
			 
		wait for 169 ns;
		
		-- Loop through the 4 data vectors
		for j in 3 downto 0 loop
			-- Loop through each vector one bit at a time
			for i in 15 downto 0 loop
		 	
		 		-- Wait until the SCK clock line is driver high by the FPGA to send
		 		--   data to the output
				wait until sck_out = '1';
				sdoa <= cha(j)(i);
				sdob <= chb(j)(i);
				sdoc <= chc(j)(i);
				sdod <= chd(j)(i);
				
				-- Generate the phase matched SCK clock
				--   (simulated by a wait statement)
				--   Data is already valid on the output at this point
				wait for 3 ns;
				sck_in <= '1';
				
				-- Generate the phase matched SCK clock 
				--   (simulated by a wait statement)
				wait until sck_out = '0';
				wait for 3 ns;
				sck_in <= '0';
		
			end loop;
			
			-- Make sure the deserialized result is correct 
			assert(std_match(cha_data, cha(j)))    -- See if result is the same.
			    report  "SPI deserialized incorrect"
			    severity  ERROR;
			assert(std_match(chb_data, chb(j)))    -- See if result is the same.
			    report  "SPI deserialized incorrect"
			    severity  ERROR;
			assert(std_match(chc_data, chc(j)))    -- See if result is the same.
			    report  "SPI deserialized incorrect"
			    severity  ERROR;
			assert(std_match(chd_data, chd(j)))    -- See if result is the same.
			    report  "SPI deserialized incorrect"
			    severity  ERROR;
		
		 end loop;


    END_SIM <= TRUE;
    wait;
  end process;

  CLOCK_CLK : process

  begin

      -- this process generates a 2.5 ns period, 50% duty cycle clock

      -- only generate clock if still simulating

      if END_SIM = FALSE then
          clock <= '0';
          wait for 1.25 ns;
      else
          wait;
      end if;

      if END_SIM = FALSE then
          clock <= '1';
          wait for 1.25 ns;
      else
          wait;
      end if;

  end process;
end spi_tb_arch;
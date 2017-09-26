    ----------------------------------------------------------------------------
--
--  SPI Interface
--
--  This is the entity declaration for the ADC SPI Interface.
--
--  Revision History:
--     2017-05-05   Torkom P.   Initial Revision
--	   2017-06-12	Torkom P. 	Fixed SPI deserializer clocking issues
--	   2017-06-13	Torkom P. 	Adjusted counter count values
--
----------------------------------------------------------------------------
--
--
--  SPI
--
--  The SPI block uses a state machine to cycle through the various stages
--	of the ADC data aquisition process.  The sample cycle asserts the conv
--  pin to command the ADC to sample analog data.  The next state is a delay
--	to prove the ADC with enough time to convert the voltage to a digital 
-- 	value.  The SCK High and Low states cycle 16 times to poll 16 data bits
-- 	from the four data channels of the ADC.  Once the clock signal has been 
--	provided, the ADC transisitions into the data ready state where it 
--	waits for the SPI deserializer to finish converting the serial data to
--	parallel or the system times out (whichever comes first).  The state 
--	machine then transitions back to the sample state and begins the
--	aquisition process again.
--
--  Inputs:
--	  sysclk      - system clock into the spi block
        
--	  sdoa        - SPI data line for ADC Channel A
--	  sdob        - SPI data line for ADC Channel B
--	  sdoc        - SPI data line for ADC Channel C
--	  sdod        - SPI data line for ADC Channel D
--	  sck_in      - Phase adjusted SCK signal from ADC
--	  RESET		  - Global Reset signal	

--  Outputs:
-- 	  conv 		  - Trigger for ADC to sample
-- 	  sck_out     - SPI Clock output to the ADC
--	  cha_data    - 16bit data from ADC Channel A
--	  chb_data    - 16bit data from ADC Channel B
--	  chc_data    - 16bit data from ADC Channel C
--	  chd_data    - 16bit data from ADC Channel D

--	  data_rdy    - Flag set by SPI block when data is ready to be read

----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.ALL;

----------------------------------------------------------------------------------
-- The sample_counter counts to 11 to set a delay for the ADC.  The sample time
-- is 30ns and we are assuming we have a 400 MHz clock which is a period of 
-- 2.5ns. This equals a count of 12 periods (11 counts and the DFF clock provides
-- a delay of 30ns.
----------------------------------------------------------------------------------

entity sample_counter is 
  port(
        sysclk, clr, en :   in  std_logic;
        finished        :   out std_logic  
  );  
end sample_counter; 

architecture behavior of sample_counter is  
  signal tmp: std_logic_vector(3 downto 0) := "0000"; 
  
  begin  
  process (sysclk, clr, en) 
    begin
        if (clr='1') then -- Reset the count value when cleared
            tmp <= "0000";  
        elsif (rising_edge(sysclk) and en = '1') then  -- Increment on each clock
            tmp <= tmp + 1; 
        end if;
  end process; 
      finished <= (tmp(3) and tmp(1) and tmp(0)); -- bits 0,1 and 3 are set 
      											  --   when the counter reaches 11
end behavior; 

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.ALL;

----------------------------------------------------------------------------------
-- The conv_counter counts to 67 to set a delay for the ADC.  The conversion time
-- is 170ns and we are assuming we have a 400 MHz clock which is a period of 
-- 2.5ns. This equals a count of 67 periods (67 counts and the DFF clock provides
-- a delay of 170ns.
----------------------------------------------------------------------------------

entity conv_counter is 
  port(
        sysclk, clr, en :   in  std_logic;
        finished        :   out std_logic  
  );  
end conv_counter; 

architecture behavior of conv_counter is  
  signal tmp: std_logic_vector(6 downto 0) := "0000000"; 
  
  begin  
  process (sysclk, clr, en) 
    begin
        if (clr='1') then  -- Reset the count values when cleared
            tmp <= "0000000";  
        elsif (rising_edge(sysclk) and en = '1') then  --Increment on each clock
            tmp <= tmp + 1; 
        end if;

  end process; 
      finished <= (tmp(6) and tmp(1) and tmp(0)); -- bits 2 and 6 are set when 
      											  --   the counter reaches 67
end behavior; 


----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.ALL;

----------------------------------------------------------------------------------
-- The if the phase matched spi clock does not work then the state machine will
-- be stuck in the data ready state.  This a timeout to get the machine back into
-- the sample state if the data takes to long to be ready
----------------------------------------------------------------------------------

entity data_timeout is 
  port(
        sysclk, clr, en :   in  std_logic;
        finished        :   out std_logic  
  );  
end data_timeout; 

architecture behavior of data_timeout is  
  signal tmp: std_logic_vector(6 downto 0) := "0000000"; 
  
  begin  
  process (sysclk, clr, en) 
    begin
        if (clr='1') then  -- Reset the count values when cleared
            tmp <= "0000000";  
        elsif (rising_edge(sysclk) and en = '1') then  -- Increment on each clock
            tmp <= tmp + 1; 
        end if;
  end process; 
      finished <= tmp(6); -- bits high bit is set when timeout reached
end behavior; 



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.ALL;

----------------------------------------------------------------------------------
-- 
----------------------------------------------------------------------------------

entity spi_deserializer is 
  port(
        reset       : in    std_logic; -- Reset signal for the bit count
        
        sdoa        : in    std_logic; -- SPI data line for ADC Channel A
        sdob        : in    std_logic; -- SPI data line for ADC Channel B
        sdoc        : in    std_logic; -- SPI data line for ADC Channel C
        sdod        : in    std_logic; -- SPI data line for ADC Channel D
        sck_in      : in    std_logic := '0'; -- Phase adjusted SCK signal from ADC 
		  
        cha_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel A
        chb_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel B
        chc_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel C 
        chd_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel D
        
        transfer_done : buffer std_logic
  );  
end spi_deserializer; 

architecture spi_deserializer_arch of spi_deserializer is  
  -- Bit counter to count when 16 bits have been aquired
  signal bit_counter: std_logic_vector(4 downto 0) := "00000";
  
  -- Temporary signals to store the serial data
  signal cha, chb, chc, chd : std_logic_vector(15 downto 0) := "0000000000000000"; 
  
  begin
  
  process (sck_in, reset) 
    begin
    	-- If reset then reset the counter back to 0
        if (reset = '1') then
            bit_counter <= "00000";
            
        else
        	if (rising_edge(sck_in)) then  
				
				-- Shift the data left one bit and add the LSBit
				cha(15 downto 1) <= cha(14 downto 0);
	            chb(15 downto 1) <= chb(14 downto 0);
	            chc(15 downto 1) <= chc(14 downto 0);
	            chd(15 downto 1) <= chd(14 downto 0);
	            
	            cha(0) <= sdoa;
	            chb(0) <= sdob;
	            chc(0) <= sdoc;
	            chd(0) <= sdod;

	            -- Increment the counter so the deserializer can keep track of
	            --  the number of bits that have been processed
	            bit_counter <= bit_counter + 1;
		            
            end if;
        end if;
  end process; 
  
  transfer_done <= bit_counter(4); 	-- Flag that lets the SPI state machine know
  									--  that the deserializer has finished
  
  -- Assign the signals to the inputs to the SPI block
  cha_data <= cha; 
  chb_data <= chb;
  chc_data <= chc;
  chd_data <= chd;
  
end spi_deserializer_arch; 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.ALL;

entity spi is
port (
		
      sysclk      : in    std_logic; -- system clock into the spi block
        
      sdoa        : in    std_logic; -- SPI data line for ADC Channel A
      sdob        : in    std_logic; -- SPI data line for ADC Channel B
      sdoc        : in    std_logic; -- SPI data line for ADC Channel C
      sdod        : in    std_logic; -- SPI data line for ADC Channel D
      sck_in      : in    std_logic; -- Phase adjusted SCK signal from ADC
		
	  conv 		  : out   std_logic := '0'; -- Trigger for ADC to sample
	  
	  RESET		  : in 	  std_logic := '1';	-- Global Reset signal	
		
      sck_out     : out   std_logic := '0'; -- SPI Clock output to the ADC
	  cha_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel A
	  chb_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel B
	  chc_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel C
	  chd_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel D
		
	  data_rdy    : buffer   std_logic := '0' -- Flag set by SPI block when data is ready to be read
    );

end spi;

architecture arch_spi of spi is
	
	component conv_counter is 
  		port(
        	sysclk, clr, en :   in  std_logic;
        	finished        :   out std_logic  
  		);  
	end component;
	
	component sample_counter is 
  		port(
        	sysclk, clr, en :   in  std_logic;
        	finished        :   out std_logic  
  		);  
	end component;
	
	component data_timeout is 
	port(
        sysclk, clr, en :   in  std_logic;
        finished        :   out std_logic  
	);  
	end component; 
	
	component spi_deserializer is 
	port(
        reset       : in    std_logic; -- Reset signal for the bit count
        
        sdoa        : in    std_logic; -- SPI data line for ADC Channel A
        sdob        : in    std_logic; -- SPI data line for ADC Channel B
        sdoc        : in    std_logic; -- SPI data line for ADC Channel C
        sdod        : in    std_logic; -- SPI data line for ADC Channel D
        sck_in      : in    std_logic := '0'; -- Phase adjusted SCK signal from ADC 
        
        cha_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel A
        chb_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel B
        chc_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel C 
        chd_data    : out   std_logic_vector(15 downto 0); -- 16bit data from ADC Channel D
        
        transfer_done : buffer std_logic
	);  
	end component; 
	
	type state is (SAMPLE, CONVERT, SCK_HIGH, SCK_LOW, DATA_READY);
	signal	cur_state  	: state := SAMPLE;			-- current state


	signal sample_counter_en, conv_counter_en 	:		std_logic := '0';
	signal data_timeout_en						: 		std_logic := '0';
	signal sample_finished, conv_finished	 	:		std_logic := '0';
	signal data_timedout						: 		std_logic := '0';
	signal clr									:  		std_logic := '1';
	signal bit_count							: 		std_logic_vector(4 downto 0) := "00000";
	signal spi_deserializer_reset               :   	std_logic := '1';
	signal sck_count                            :   	std_logic := '0';
	
	
begin
	
	-- Create instances of the counters
	sampleCntr : sample_counter port map (
		sysclk => sysclk, 
		clr => (clr or not RESET), 
		en => sample_counter_en, 
		finished => sample_finished );
	convCntr   : conv_counter 	port map (
		sysclk => sysclk, 
		clr => (clr or not RESET), 
		en => conv_counter_en, 
		finished => conv_finished );
	dataTimeout : data_timeout port map (
		sysclk => sysclk, 
		clr => (clr or not RESET), 
		en => data_timeout_en, 
		finished => data_timedout );
	
	-- Create an instance of the SPI deserializer
	spiDeserializer : spi_deserializer port map(
		reset => spi_deserializer_reset, 
		sdoa => sdoa, 
		sdob => sdob, 
		sdoc => sdoc, 
		sdod => sdod,
		sck_in => sck_in,
		cha_data => cha_data, 
		chb_data => chb_data, 
		chc_data => chc_data, 
		chd_data => chd_data, 
		transfer_done => data_rdy);
	
	-- state transitions for the scanning and debouncing state machine
	transition:  process (sysclk)
		begin
			
			-- clock on the rising edge
			if  rising_edge(sysclk)   then
			
				-- state transitions
				case  cur_state  is       -- do the state transitions

					when  SAMPLE =>       -- ADC sample aquisition state
						
						-- make sure the result ready signal is reset to 0
						clr <= '0';
						sample_counter_en <= '1';
						
						conv <= '1';
						
						-- keep looping until the ADC has finished sampling
						if (sample_finished = '1') then
							cur_state <= CONVERT;
							-- Reset the counter and disable it
							sample_counter_en <= '0';
							clr <= '1';		
							conv <= '0';
						elsif RESET = '0' then
							cur_state <= SAMPLE;
						else
							cur_state <= SAMPLE;
						end if;
					
					when CONVERT =>  -- Provide the ADC with time to convert the signal
						
						clr <= '0';
						conv_counter_en <= '1';
						
						
						-- keep looping until the ADC has finished converting the sample
						if (conv_finished = '1') then
							cur_state <= SCK_HIGH;
							
							-- Reset the counter and disable it
							conv_counter_en <= '0';
							clr <= '1';
							
							-- Initialize the SCK clock counter to 0
							sck_count <= '0';

							-- Reset the SPI deserializer
							spi_deserializer_reset <= '1';
						
						elsif RESET = '0' then
							cur_state <= SAMPLE;
						
						else
							cur_state <= CONVERT;
						end if;
						
					when  SCK_HIGH  =>     -- SPI clock high period
						
					   	spi_deserializer_reset <= '0';

					   	-- If 16 bits have been counted out then go to
					   	-- the next state
					   	if (bit_count(4) = '1') then
					   		sck_out <= '0';
                        	bit_count <= "00000";
                        	cur_state <= DATA_READY;
									clr <= '1';

						-- clock high period should be 5 ns which is two
						-- clock cycles for the fpga
						-- The delay is done using a single bit counter
					   	elsif (sck_count = '0') then
					      	sck_out <= '1';
						  	cur_state <= SCK_HIGH;
						  	sck_count <= '1';
					   	elsif RESET = '0' then
					   		-- Handle a reset signal
							cur_state <= SAMPLE;
					   	else
						  	sck_out <= '1';
						  	cur_state <= SCK_LOW;
						  	sck_count <= '0';
					   	end if;
					
						
					when SCK_LOW   =>     -- SPI clock low period
                                                
                        spi_deserializer_reset <= '0';
                        
                        sck_out <= '0';
                        
                        
                        -- clock low period should be 5 ns which is two
						-- clock cycles for the fpga
						-- The delay is done using a single bit counter
                        if (sck_count = '0') then
                            cur_state <= SCK_LOW;
                            sck_count <= '1';
                        elsif RESET = '0' then
                        	-- Handle a reset signal
							cur_state <= SAMPLE;
                        else
                            cur_state <= SCK_HIGH;
                            sck_count <= '0';
                            bit_count <= bit_count + 1;
                        end if;	
					
					when  DATA_READY =>      -- 
						
						-- Reset the counters
						clr <= '0';
						
						-- Enable the data timeout counter
						data_timeout_en <= '1';
						
						-- Wait until the deserializer finishes parsing the
						-- data or the timeout period is over
						if(data_rdy = '1' or data_timedout = '1') then
							
							-- Start another sample
							cur_state <= SAMPLE;
							spi_deserializer_reset <= '1';
							
							-- Reset the counter and disable the data timeout counter
							clr <= '1';
							data_timeout_en <= '0';
						elsif RESET = '0' then
							-- Handle a reset signal
							cur_state <= SAMPLE;
						else
							-- Keep looping until a valid state transition is available
							cur_state <= DATA_READY;
						end if;
				end case;
			end if;
	end process transition;
	
end arch_spi;
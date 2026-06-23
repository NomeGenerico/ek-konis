library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;


--################
-- Placa de Som
--################
ENTITY SB IS

	PORT
	(
        -- Entrada de clock
			clock_25Mhz				: IN	STD_LOGIC;
			reset				: IN	STD_LOGIC;
        -- Entrada para os dados

			SB_DataIn : IN  STD_LOGIC_VECTOR(15 .,kmj m DOWNTO 0);

		-- Saida Dados

			data_out   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)

        -- Saida GPIO
            audio_out   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)

	);
END SB;

ARCHITECTURE behavior OF SB IS

    -- Define LUT
    type LUT_ARRAY is array (0 to 255) of STD_LOGIC_VECTOR(3 downto 0);
    
    signal sine_lut : LUT_ARRAY := (
        -- Your sine wave values here
        others => x"80"
    );

	-- Valores de Controle
	signal freq_c1 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
	signal freq_c2 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
	signal freq_c3 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
	signal freq_c4 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');

    -- Acumuladores de fase para os 4 canais (28 bits)
    signal acc_c1 : STD_LOGIC_VECTOR(27 DOWNTO 0) := (others => '0');
    signal acc_c2 : STD_LOGIC_VECTOR(27 DOWNTO 0) := (others => '0');
    signal acc_c3 : STD_LOGIC_VECTOR(27 DOWNTO 0) := (others => '0');
    signal acc_c4 : STD_LOGIC_VECTOR(27 DOWNTO 0) := (others => '0');

    -- Sinais das formas de onda individuais (8 bits)
    signal wave_c1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal wave_c2 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal wave_c3 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal wave_c4 : STD_LOGIC_VECTOR(7 DOWNTO 0);

	-- Playback (+1 every span of time defined by the BPM)
	signal PB_Pos
	signal PB_counter : STD_LOGIC_VECTOR(27 DOWNTO 0) := (others => '0');
	 
	 -- Constantes
	 CONSTANT Clock_freq      : STD_LOGIC_VECTOR (31 downto 0) := "000000000000000000000000000000000";  -- 25Mhz
	 CONSTANT Clock_freq_reset      : STD_LOGIC_VECTOR (31 downto 0) := "1110111001101011001010000000";  -- 25Mhz * 10

	 -- Instructions


BEGIN

	-- Reccurent Behaviour

	    -- Read all four LUT entries in parallel
    		wave_c1 <= sine_lut(to_integer(unsigned(acc_c1(27 downto 20))));
    		wave_c2 <= sine_lut(to_integer(unsigned(acc_c2(27 downto 20))));
    		wave_c3 <= sine_lut(to_integer(unsigned(acc_c3(27 downto 20))));
    		wave_c4 <= sine_lut(to_integer(unsigned(acc_c4(27 downto 20))));

--#########################
-- Maquina de Controle
--#########################

process(clk, reset)

	  variable state : STATES;  -- Estados do SoundBoard: fetch, exec

	if(reset = '1') then
	
	
	end if;
   
	
	end process;
	
--############################
-- Geradores de Frequncia --
--############################

process(clk, reset)

	variable temp_acc_c1      : STD_LOGIC_VECTOR(31 downto 0);
	variable temp_acc_c2      : STD_LOGIC_VECTOR(31 downto 0);
	variable temp_acc_c3      : STD_LOGIC_VECTOR(31 downto 0);
	variable temp_acc_c4      : STD_LOGIC_VECTOR(31 downto 0);
	
	variable indice_LUT_1     : STD_LOGIC_VECTOR( 7 downto 0);
	
	variable mixer_sum        : STD_LOGIC_VECTOR( 9 downto 0);

	if(clk'event and clk = '1') then
	-- qureremos uma resolução de 0.1 hz. Isso é feito com o Clock_freq_reset
	
		-- Somar os acumuladores a freqeuncia
		temp_acc_c1 <= acc_c1 + freq_c1
		temp_acc-c2 <= acc_c2 + freq_c2
		temp_acc_c3 <= acc_c3 + freq_c3
		temp_acc-c4 <= acc_c4 + freq_c4
		
		-- Wrap Around
		if(temp_acc_c1 > Clock_freq_reset)
			temp_acc_c1 := temp_acc_c1 - Clock_freq_reset
		end if;
		if(temp_acc_c2 > Clock_freq_reset)
			temp_acc_c2 := temp_acc_c2 - Clock_freq_reset
		end if;
		if(temp_acc_c3 > Clock_freq_reset)
			temp_acc_c3 := temp_acc_c3 - Clock_freq_reset
		end if;
		if(temp_acc_c4 > Clock_freq_reset)
			temp_acc_c4 := temp_acc_c4 - Clock_freq_reset
		end if;
		
		-- Pegar valures na LUT 
		
   end process;




-- Mixer --
	if(clk'event and clk = '1') then

		-- somar os quatro canais e dividir por 4
		-- mixer_sum := ((Sum of LUTs) >> 2)   -- valores pegos do LUT

   end process;


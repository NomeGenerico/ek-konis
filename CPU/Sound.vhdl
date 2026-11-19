library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;      -- substitui STD_LOGIC_ARITH / STD_LOGIC_UNSIGNED (nao-padrao)


--################
-- Placa de Som
--################
ENTITY SB IS

	PORT
	(
		-- Entrada de clock
			clk            : IN  STD_LOGIC;
			clock_25Mhz    : IN  STD_LOGIC;
			clock_1Mhz     : IN  STD_LOGIC;
			reset          : IN  STD_LOGIC;

		-- Entrada para os dados
			SB_DataIn      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);

		-- Saida Dados
			data_out       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

		-- Saida GPIO
			audio_out      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

		-- Controle
			IS_Instruction : IN  STD_LOGIC
	);
END SB;

ARCHITECTURE behavior OF SB IS

	-- Define LUT (1 periodo completo de senoide, 256 amostras de 4 bits)
	type LUT_ARRAY is array (0 to 255) of STD_LOGIC_VECTOR(3 downto 0);

    CONSTANT sine_lut : LUT_ARRAY := (
        "1000", "1000", "1000", "1000", "1000", "1000", "1001", "1001",
        "1001", "1001", "1001", "1010", "1010", "1010", "1010", "1010",
        "1010", "1011", "1011", "1011", "1011", "1011", "1011", "1100",
        "1100", "1100", "1100", "1100", "1100", "1100", "1101", "1101",
        "1101", "1101", "1101", "1101", "1101", "1101", "1110", "1110",
        "1110", "1110", "1110", "1110", "1110", "1110", "1110", "1110",
        "1110", "1110", "1111", "1111", "1111", "1111", "1111", "1111",
        "1111", "1111", "1111", "1111", "1111", "1111", "1111", "1111",
        "1111", "1111", "1111", "1111", "1111", "1111", "1111", "1111",
        "1111", "1111", "1111", "1111", "1111", "1111", "1111", "1110",
        "1110", "1110", "1110", "1110", "1110", "1110", "1110", "1110",
        "1110", "1110", "1110", "1101", "1101", "1101", "1101", "1101",
        "1101", "1101", "1101", "1100", "1100", "1100", "1100", "1100",
        "1100", "1100", "1011", "1011", "1011", "1011", "1011", "1011",
        "1010", "1010", "1010", "1010", "1010", "1010", "1001", "1001",
        "1001", "1001", "1001", "1000", "1000", "1000", "1000", "1000",
        "1000", "0111", "0111", "0111", "0111", "0111", "0110", "0110",
        "0110", "0110", "0110", "0101", "0101", "0101", "0101", "0101",
        "0101", "0100", "0100", "0100", "0100", "0100", "0100", "0011",
        "0011", "0011", "0011", "0011", "0011", "0011", "0010", "0010",
        "0010", "0010", "0010", "0010", "0010", "0010", "0001", "0001",
        "0001", "0001", "0001", "0001", "0001", "0001", "0001", "0001",
        "0001", "0001", "0000", "0000", "0000", "0000", "0000", "0000",
        "0000", "0000", "0000", "0000", "0000", "0000", "0000", "0000",
        "0000", "0000", "0000", "0000", "0000", "0000", "0000", "0000",
        "0000", "0000", "0000", "0000", "0000", "0000", "0000", "0001",
        "0001", "0001", "0001", "0001", "0001", "0001", "0001", "0001",
        "0001", "0001", "0001", "0010", "0010", "0010", "0010", "0010",
        "0010", "0010", "0010", "0011", "0011", "0011", "0011", "0011",
        "0011", "0011", "0100", "0100", "0100", "0100", "0100", "0100",
        "0101", "0101", "0101", "0101", "0101", "0101", "0110", "0110",
        "0110", "0110", "0110", "0111", "0111", "0111", "0111", "0111"
   	 );

	-- Estado de controle
		signal IR            : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');  -- ultima instrucao (debug)
		signal IS_Instr_prev : STD_LOGIC := '0';                                  -- para detectar borda de IS_Instruction
		signal last_sb_in    : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');  -- SB_DataIn do clock anterior

	-- Palavras de sintonia (tuning words) dos 4 canais: f_saida = palavra * 25MHz / 2^28
	-- O processador envia a frequencia em unidades de 0,1 Hz (10000 = 1 kHz);
	-- a conversao para palavra de sintonia e feita por to_tuning() na hora de gravar.
		signal freq_c1 : UNSIGNED(16 DOWNTO 0) := (others => '0');
		signal freq_c2 : UNSIGNED(16 DOWNTO 0) := (others => '0');
		signal freq_c3 : UNSIGNED(16 DOWNTO 0) := (others => '0');
		signal freq_c4 : UNSIGNED(16 DOWNTO 0) := (others => '0');

	-- General Playback
		signal ISPlaying     : STD_LOGIC := '0';

	-- Immediate Playing
		signal isImedPlaying : STD_LOGIC := '0';
		signal NewNoteDuration : STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');

		-- Handshake entre dominios de clock (clk <-> clock_25Mhz) por "toggle":
		--   note_toggle muda a cada nota imediata nova  (clk -> 25MHz)
		--   end_toggle  muda quando a nota termina      (25MHz -> clk)
		signal note_toggle : STD_LOGIC := '0';
		signal end_toggle  : STD_LOGIC := '0';
		signal note_s1, note_s2, note_s3 : STD_LOGIC := '0';   -- sincronizador no dominio 25MHz
		signal end_s1,  end_s2,  end_s3  : STD_LOGIC := '0';   -- sincronizador no dominio clk

		-- Sincronizadores de ISPlaying
		signal play_n1, play_n2 : STD_LOGIC := '0';            -- dominio 25MHz
		signal play_o1, play_o2 : STD_LOGIC := '0';            -- dominio 1MHz

	-- Acumuladores de fase dos 4 canais (28 bits, overflow natural = 1 periodo)
		signal acc_c1 : UNSIGNED(27 DOWNTO 0) := (others => '0');
		signal acc_c2 : UNSIGNED(27 DOWNTO 0) := (others => '0');
		signal acc_c3 : UNSIGNED(27 DOWNTO 0) := (others => '0');
		signal acc_c4 : UNSIGNED(27 DOWNTO 0) := (others => '0');

	-- LUT Indexes (8 bits de cima do acumulador -> 2^8 = 256 entradas)
		signal LUTI_c1 : UNSIGNED(7 DOWNTO 0);
		signal LUTI_c2 : UNSIGNED(7 DOWNTO 0);
		signal LUTI_c3 : UNSIGNED(7 DOWNTO 0);
		signal LUTI_c4 : UNSIGNED(7 DOWNTO 0);

	-- Formas de onda individuais (4 bits)
		signal wave_c1 : STD_LOGIC_VECTOR(3 DOWNTO 0);
		signal wave_c2 : STD_LOGIC_VECTOR(3 DOWNTO 0);
		signal wave_c3 : STD_LOGIC_VECTOR(3 DOWNTO 0);
		signal wave_c4 : STD_LOGIC_VECTOR(3 DOWNTO 0);

	-- Pulso de 1 ciclo de clock_25Mhz a cada 1 ms
		signal ms_tick : STD_LOGIC := '0';

	-- Constantes
		CONSTANT MS_DIV        : INTEGER := 25000;                        -- 25 MHz / 25000 = 1 kHz

	-- Instructions (IR(12..10))
		CONSTANT START_Playback : STD_LOGIC_VECTOR (2 DOWNTO 0) := "000";
		CONSTANT STOP_Playback  : STD_LOGIC_VECTOR (2 DOWNTO 0) := "001";
		CONSTANT Imed_PLAY      : STD_LOGIC_VECTOR (2 DOWNTO 0) := "010";


	-- Converte frequencia em unidades de 0,1 Hz (ex.: 10000 = 1 kHz) para a palavra de sintonia do NCO:
	--   palavra = f * 2^28 / 250.000.000 = f * 1,073741824  ~= (f * 70369) / 65536  (com arredondamento)
	-- Erro < 0,001 %; a conversao so e feita quando a frequencia e gravada (1 multiplicador no total).
	function to_tuning(f : UNSIGNED(15 DOWNTO 0)) return UNSIGNED is
		variable p : UNSIGNED(32 DOWNTO 0);
	begin
		p := f * to_unsigned(70369, 17) + to_unsigned(32768, 33);
		return p(32 DOWNTO 16);          -- 17 bits (max 65535 -> 70368)
	end function;

BEGIN

	-- Saida de dados nao era driven no original (ficava 'U')
	data_out <= (others => '0');

	-- Pegar valores na LUT
	-- Usamos apenas os 8 bits de cima do acumulador de fase para enderecar a LUT
	LUTI_c1 <= acc_c1(27 DOWNTO 20);
	LUTI_c2 <= acc_c2(27 DOWNTO 20);
	LUTI_c3 <= acc_c3(27 DOWNTO 20);
	LUTI_c4 <= acc_c4(27 DOWNTO 20);

	wave_c1 <= sine_lut(to_integer(LUTI_c1));
	wave_c2 <= sine_lut(to_integer(LUTI_c2));
	wave_c3 <= sine_lut(to_integer(LUTI_c3));
	wave_c4 <= sine_lut(to_integer(LUTI_c4));


--#########################
-- Maquina de Controle (dominio clk)
--#########################
MaquinaDeControle: process(clk, reset)

	variable Temp_freq_c4 : UNSIGNED(16 DOWNTO 0) := (others => '0');
	variable op           : STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN

	if (reset = '1') then

		ISPlaying       <= '0';
		isImedPlaying   <= '0';
		NewNoteDuration <= (others => '0');
		note_toggle     <= '0';
		IR              <= (others => '0');
		IS_Instr_prev   <= '0';
		last_sb_in      <= (others => '0');
		end_s1 <= '0';  end_s2 <= '0';  end_s3 <= '0';

		freq_c1 <= (others => '0');
		freq_c2 <= (others => '0');
		freq_c3 <= (others => '0');
		freq_c4 <= (others => '0');

		Temp_freq_c4 := (others => '0');

	elsif rising_edge(clk) then

		-- Guarda o que a CPU colocou no barramento neste clock
		-- (dentro do processo, last_sb_in ainda tem o valor do clock ANTERIOR)
		last_sb_in <= SB_DataIn;

		-- Sincroniza o aviso de "nota terminou" vindo do dominio 25MHz
		end_s1 <= end_toggle;
		end_s2 <= end_s1;
		end_s3 <= end_s2;

		IS_Instr_prev <= IS_Instruction;

		-- Fim da nota imediata: restaura a frequencia anterior do canal 4
		if (end_s2 /= end_s3) then
			isImedPlaying <= '0';
			freq_c4       <= Temp_freq_c4;
		end if;

		-- IS_Instruction so sobe em instrucao de som.
		-- Protocolo: last_sb_in = palavra de instrucao (clock anterior), SB_DataIn = palavra de dados (agora)
		if (IS_Instruction = '1' and IS_Instr_prev = '0') then

			IR <= last_sb_in;
			op := last_sb_in(12 DOWNTO 10);

--========================================================================
-- START_Playback
--========================================================================
				if (op = START_Playback) then
					ISPlaying <= '1';

--========================================================================
-- STOP_Playback
--========================================================================
				elsif (op = STOP_Playback) then
					ISPlaying <= '0';

--========================================================================
-- Imed_PLAY: duracao (ms) em instr(9..0), frequencia (0,1 Hz) na palavra de dados
--========================================================================
				elsif (op = Imed_PLAY) then
					NewNoteDuration <= last_sb_in(9 DOWNTO 0);       -- ate 1023 ms

					-- So guarda a frequencia original se nao havia nota imediata tocando
					if (isImedPlaying = '0') then
						Temp_freq_c4 := freq_c4;
					end if;

					freq_c4       <= to_tuning(unsigned(SB_DataIn));
					ISPlaying     <= '1';
					isImedPlaying <= '1';
					note_toggle   <= not note_toggle;                -- avisa o SoundEngine
				end if;

		end if;

	end if;

END process MaquinaDeControle;


--############################
-- Geradores de Frequencia (NCO, dominio 25MHz)
--############################
GeradorDeFreq: process(clock_25Mhz, reset)
BEGIN

	if (reset = '1') then

		acc_c1 <= (others => '0');
		acc_c2 <= (others => '0');
		acc_c3 <= (others => '0');
		acc_c4 <= (others => '0');
		play_n1 <= '0';
		play_n2 <= '0';

	elsif rising_edge(clock_25Mhz) then

		play_n1 <= ISPlaying;
		play_n2 <= play_n1;

		if (play_n2 = '1') then
			-- Soma a palavra de sintonia; o overflow de 28 bits e o proprio "wrap" do periodo
			acc_c1 <= acc_c1 + resize(freq_c1, 28);
			acc_c2 <= acc_c2 + resize(freq_c2, 28);
			acc_c3 <= acc_c3 + resize(freq_c3, 28);
			acc_c4 <= acc_c4 + resize(freq_c4, 28);
		end if;

	end if;

END process GeradorDeFreq;


--############################
-- Clock de 1 ms (pulso, dominio 25MHz)
--############################
MSClock: process(clock_25Mhz, reset)

	variable ms_cnt : INTEGER range 0 to MS_DIV-1 := 0;

BEGIN

	if (reset = '1') then

		ms_cnt  := 0;
		ms_tick <= '0';

	elsif rising_edge(clock_25Mhz) then

		if (ms_cnt = MS_DIV-1) then
			ms_cnt  := 0;
			ms_tick <= '1';
		else
			ms_cnt  := ms_cnt + 1;
			ms_tick <= '0';
		end if;

	end if;

END process MSClock;


--############################
-- Duracao da nota imediata (dominio 25MHz)
--############################
SoundEngine: process(clock_25Mhz, reset)

	variable NoteDuration : UNSIGNED(9 DOWNTO 0) := (others => '0');
	variable note_active  : BOOLEAN := false;

BEGIN

	if (reset = '1') then

		NoteDuration := (others => '0');
		note_active  := false;
		end_toggle   <= '0';
		note_s1 <= '0';  note_s2 <= '0';  note_s3 <= '0';

	elsif rising_edge(clock_25Mhz) then

		note_s1 <= note_toggle;
		note_s2 <= note_s1;
		note_s3 <= note_s2;

		-- Nova nota: carrega a duracao
		if (note_s2 /= note_s3) then

			NoteDuration := unsigned(NewNoteDuration);
			note_active  := true;

		-- A cada 1 ms, desconta a duracao
		elsif (ms_tick = '1' and note_active) then

			if (NoteDuration = 0) then
				note_active := false;
				end_toggle  <= not end_toggle;   -- avisa a maquina de controle
			else
				NoteDuration := NoteDuration - 1;
			end if;

		end if;

	end if;

END process SoundEngine;


--############################
-- Saida final: 250 kHz (clock_1Mhz / 4 como clock-enable)
--############################
FINALOUTPUT: process(clock_1Mhz, reset)

	variable clk_div : UNSIGNED(1 DOWNTO 0) := (others => '0');
	variable sum     : UNSIGNED(5 DOWNTO 0);

BEGIN

	if (reset = '1') then

		clk_div   := (others => '0');
		play_o1   <= '0';
		play_o2   <= '0';
		audio_out <= "1000";                 -- nivel medio (silencio)

	elsif rising_edge(clock_1Mhz) then

		play_o1 <= ISPlaying;
		play_o2 <= play_o1;

		clk_div := clk_div + 1;

		if (clk_div = 0) then                -- 1 MHz / 4 = 250 kHz

			if (play_o2 = '1') then
				-- Soma dos 4 canais (max 4*15 = 60 -> cabe em 6 bits); saida = soma/4
				sum := resize(unsigned(wave_c1), 6) + resize(unsigned(wave_c2), 6)
				     + resize(unsigned(wave_c3), 6) + resize(unsigned(wave_c4), 6);
				audio_out <= std_logic_vector(sum(5 DOWNTO 2));
			else
				audio_out <= "1000";         -- nivel medio quando parado
			end if;

		end if;

	end if;

END process FINALOUTPUT;

END behavior;

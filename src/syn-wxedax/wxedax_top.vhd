-------------------------------------------------------------------------------
--
-- MSX1 FPGA project
--
-- Copyright (c) 2016, Fabio Belavenuto (belavenuto@gmail.com)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity wxedax_top is
	port (
		-- Clock (48MHz)
		clock_48M_i				: in    std_logic;
		-- SDRAM (W9864G6JH = 4Mx16 = 8MB)
		sdram_clock_o			: out   std_logic									:= '0';
		sdram_cke_o    	  	: out   std_logic									:= '0';
		sdram_addr_o			: out   std_logic_vector(11 downto 0)		:= (others => '0');
		sdram_dq_io				: inout std_logic_vector(15 downto 0);
		sdram_ba_o				: out   std_logic_vector( 1 downto 0)		:= (others => '0');
		sdram_dqml_o			: out   std_logic;
		sdram_dqmh_o			: out   std_logic;
		sdram_cs_n_o   	  	: out   std_logic									:= '1';
		sdram_we_n_o			: out   std_logic									:= '1';
		sdram_cas_n_o			: out   std_logic									:= '1';
		sdram_ras_n_o			: out   std_logic									:= '1';
		-- SPI FLASH (FPGA and Aux)
		flashf_clk_o			: out   std_logic									:= '0';
		flashf_data_i			: in    std_logic;
		flashf_data_o			: out   std_logic									:= '0';
		flashf_cs_n_o			: out   std_logic									:= '1';
--		flash2_clk_o			: out   std_logic									:= '0';
--		flash2_data_i			: in    std_logic;
--		flash2_data_o			: out   std_logic									:= '0';
		flash2_cs_n_o			: out   std_logic									:= '1';
		-- VGA 5:6:5
		vga_r_o					: out   std_logic_vector(4 downto 0)		:= (others => '0');
		vga_g_o					: out   std_logic_vector(5 downto 0)		:= (others => '0');
		vga_b_o					: out   std_logic_vector(4 downto 0)		:= (others => '0');
		vga_hs_o					: out   std_logic									:= '1';
		vga_vs_o					: out   std_logic									:= '1';
--		-- UART
--		uart_tx_o				: out   std_logic									:= '1';
--		uart_rx_i				: in    std_logic;
		-- Keys and Leds
		keys_n_i					: in    std_logic_vector(3 downto 0);
		leds_n_o					: out   std_logic_vector(3 downto 0)		:= (others => '1');
		-- PS/2 Keyboard
		ps2_clk_io				: inout std_logic									:= 'Z';
		ps2_dat_io		 		: inout std_logic									:= 'Z';
		-- ADC
		adc_clock_o				: out   std_logic									:= '0';
		adc_data_i				: in    std_logic;
		adc_cs_n_o				: out   std_logic									:= '1';
		-- Audio
		audio_dac_l_o			: out   std_logic									:= '0';
		audio_dac_r_o			: out   std_logic									:= '0';
		buzzer_o					: out   std_logic									:= '1';
		-- SD Card
		sd_sclk_o				: out   std_logic									:= '0';
		sd_mosi_o				: out   std_logic									:= '0';
		sd_miso_i				: in    std_logic;
		sd_cs_n_o				: out   std_logic									:= '1';
		-- Joystick SNES
		pad_clk_o				: out   std_logic								:= '0';
		pad_latch_o				: out   std_logic								:= '0';
		pad_data_i				: in    std_logic
		-- Others
--		irda_o					: out   std_logic									:= '0';
--		gpio_io					: inout std_logic_vector(1 downto 0)
	);
end;

architecture behavior of wxedax_top is

	-- Resets
	signal por_cnt_s			: unsigned(7 downto 0)				:= (others => '1');
	signal por_clock_s		: std_logic;
	signal por_s				: std_logic;
	signal reset_s				: std_logic;
	signal soft_por_s			: std_logic;
	signal soft_reset_k_s	: std_logic;
	signal soft_reset_s_s	: std_logic;
	signal soft_rst_cnt_s	: unsigned(7 downto 0)	:= X"FF";

	-- Clocks
	signal clock_master_s	: std_logic;
	signal clock_sdram_s		: std_logic;
	signal clock_sdram_o_s	: std_logic;
	signal clock_vdp_s		: std_logic;
	signal clock_cpu_s		: std_logic;
	signal clock_psg_en_s	: std_logic;
	signal clock_3m_s			: std_logic;
	signal turbo_on_s			: std_logic;

	-- RAM
	signal ram_addr_s			: std_logic_vector(18 downto 0);		-- 512K
	signal ram_data_from_s	: std_logic_vector( 7 downto 0);
	signal ram_data_to_s		: std_logic_vector( 7 downto 0);
	signal ram_ce_s			: std_logic;
	signal ram_oe_s			: std_logic;
	signal ram_we_s			: std_logic;

	-- ROM
	signal rom_addr_s			: std_logic_vector(14 downto 0);		-- 32K
	signal rom_data_s			: std_logic_vector(7 downto 0);
	signal rom_ce_s			: std_logic;
	signal rom_oe_s			: std_logic;

	-- SDRAM
	signal sdram_addr_s		: std_logic_vector(22 downto 0);		-- 8MB

	-- VRAM memory
	signal vram_addr_s		: std_logic_vector(13 downto 0);		-- 16K
	signal vram_do_s			: std_logic_vector( 7 downto 0);
	signal vram_di_s			: std_logic_vector( 7 downto 0);
--	signal vram_ce_s			: std_logic;
--	signal vram_oe_s			: std_logic;
	signal vram_we_s			: std_logic;

	-- Audio
	signal audio_scc_s		: signed(14 downto 0);
	signal audio_psg_s		: unsigned(7 downto 0);
	signal beep_s				: std_logic;
	signal dac_s				: std_logic;
	signal tapein_s			: std_logic_vector(7 downto 0);
	signal ear_s				: std_logic;

	-- Video
	signal rgb_r_s				: std_logic_vector( 3 downto 0);
	signal rgb_g_s				: std_logic_vector( 3 downto 0);
	signal rgb_b_s				: std_logic_vector( 3 downto 0);
	signal rgb_hsync_n_s		: std_logic;
	signal rgb_vsync_n_s		: std_logic;
	signal vga_en_s			: std_logic;
	signal ntsc_pal_s			: std_logic;

	-- Keyboard
	signal rows_s				: std_logic_vector( 3 downto 0);
	signal cols_s				: std_logic_vector( 7 downto 0);
	signal caps_en_s			: std_logic;
	signal extra_keys_s		: std_logic_vector(3 downto 0);
	signal keymap_addr_s		: std_logic_vector(9 downto 0);
	signal keymap_data_s		: std_logic_vector(7 downto 0);
	signal keymap_we_s		: std_logic;
	
	-- SD
	signal sd_cs_n_s			: std_logic;

	-- SNES
	signal but_a_s				: std_logic;
	signal but_b_s				: std_logic;
	signal but_x_s				: std_logic;
	signal but_y_s				: std_logic;
	signal but_start_s		: std_logic;
	signal but_sel_s			: std_logic;
	signal but_tl_s			: std_logic;
	signal but_tr_s			: std_logic;
	signal but_up_s			: std_logic;
	signal but_down_s			: std_logic;
	signal but_left_s			: std_logic;
	signal but_right_s		: std_logic;

begin

	-- PLL
	pll_1: entity work.pll1
	port map (
		CLK_IN1	=> clock_48M_i,
		CLK_OUT1	=> clock_master_s,		-- 21.46667 MHz (6x NTSC)
		CLK_OUT2	=> clock_sdram_s,			-- 85.86667 MHz (4x master)
		CLK_OUT3	=> sdram_clock_o			-- clock sdram -45 degrees
	);

	-- Clocks
	clks: entity work.clocks
	port map (
		clock_i			=> clock_master_s,
		por_i				=> por_clock_s,
		turbo_on_i		=> turbo_on_s,
		clock_vdp_o		=> clock_vdp_s,
		clock_5m_en_o	=> open,
		clock_cpu_o		=> clock_cpu_s,
		clock_psg_en_o	=> clock_psg_en_s,
		clock_3m_o		=> clock_3m_s
	);

	-- The MSX1
	the_msx: entity work.msx
	generic map (
		hw_id_g			=> 9,
		hw_txt_g			=> "WXEDAX Board",
		hw_version_g	=> X"11",				-- Version 1.1
		video_opt_g		=> 1						-- dblscan configurable
	)
	port map (
		-- Clocks
		clock_i			=> clock_master_s,
		clock_vdp_i		=> clock_vdp_s,
		clock_cpu_i		=> clock_cpu_s,
		clock_psg_en_i	=> clock_psg_en_s,
		-- Turbo
		turbo_on_k_i	=> extra_keys_s(3),	-- F12
		turbo_on_o		=> turbo_on_s,
		-- Resets
		reset_i			=> reset_s,
		por_i				=> por_s,
		softreset_o		=> soft_reset_s_s,
		-- Options
		opt_nextor_i	=> '1',
		opt_mr_type_i	=> "00",
		opt_vga_on_i	=> '1',
		-- RAM
		ram_addr_o		=> ram_addr_s,
		ram_data_i		=> ram_data_from_s,
		ram_data_o		=> ram_data_to_s,
		ram_ce_o			=> ram_ce_s,
		ram_we_o			=> ram_we_s,
		ram_oe_o			=> ram_oe_s,
		-- ROM
		rom_addr_o		=> rom_addr_s,
		rom_data_i		=> rom_data_s,
		rom_ce_o			=> rom_ce_s,
		rom_oe_o			=> rom_oe_s,
		-- External bus
		bus_addr_o		=> open,
		bus_data_i		=> (others => '1'),
		bus_data_o		=> open,
		bus_rd_n_o		=> open,
		bus_wr_n_o		=> open,
		bus_m1_n_o		=> open,
		bus_iorq_n_o	=> open,
		bus_mreq_n_o	=> open,
		bus_sltsl1_n_o	=> open,
		bus_sltsl2_n_o	=> open,
		bus_wait_n_i	=> '1',
		bus_nmi_n_i		=> '1',
		bus_int_n_i		=> '1',
		-- VDP RAM
		vram_addr_o		=> vram_addr_s,
		vram_data_i		=> vram_do_s,
		vram_data_o		=> vram_di_s,
		vram_ce_o		=> open,--vram_ce_s,
		vram_oe_o		=> open,--vram_oe_s,
		vram_we_o		=> vram_we_s,
		-- Keyboard
		rows_o			=> rows_s,
		cols_i			=> cols_s,
		caps_en_o		=> caps_en_s,
		keymap_addr_o	=> keymap_addr_s,
		keymap_data_o	=> keymap_data_s,
		keymap_we_o		=> keymap_we_s,
		-- Audio
		audio_scc_o		=> audio_scc_s,
		audio_psg_o		=> audio_psg_s,
		beep_o			=> beep_s,
		-- K7
		k7_motor_o		=> open,
		k7_audio_o		=> open,
		k7_audio_i		=> ear_s,
		-- Joystick
		joy1_up_i		=> but_up_s,
		joy1_down_i		=> but_down_s,
		joy1_left_i		=> but_left_s,
		joy1_right_i	=> but_right_s,
		joy1_btn1_i		=> but_b_s,
		joy1_btn1_o		=> open,
		joy1_btn2_i		=> but_a_s,
		joy1_btn2_o		=> open,
		joy1_out_o		=> open,
		joy2_up_i		=> '1',
		joy2_down_i		=> '1',
		joy2_left_i		=> '1',
		joy2_right_i	=> '1',
		joy2_btn1_i		=> '1',
		joy2_btn1_o		=> open,
		joy2_btn2_i		=> '1',
		joy2_btn2_o		=> open,
		joy2_out_o		=> open,
		-- Video
		rgb_r_o			=> rgb_r_s,
		rgb_g_o			=> rgb_g_s,
		rgb_b_o			=> rgb_b_s,
		hsync_n_o		=> rgb_hsync_n_s,
		vsync_n_o		=> rgb_vsync_n_s,
		ntsc_pal_o		=> ntsc_pal_s,
		vga_on_k_i		=> extra_keys_s(2),		-- Print Screen
		vga_en_o			=> vga_en_s,
		-- SPI/SD
		flspi_cs_n_o	=> open,
		spi_cs_n_o		=> sd_cs_n_s,
		spi_sclk_o		=> sd_sclk_o,
		spi_mosi_o		=> sd_mosi_o,
		spi_miso_i		=> sd_miso_i,
		-- DEBUG
		D_wait_o			=> open,
		D_slots_o		=> open
	);

	-- ROM
	rom: entity work.mainrom
	port map (
		clk		=> clock_master_s,
		addr		=> rom_addr_s,
		data		=> rom_data_s
	);

	-- RAM
	sdram_addr_s	<= "0000" & ram_addr_s;

	ram: entity work.ssdram
	generic map (
		freq_g		=> 85
	)
	port map (
		clock_i		=> clock_sdram_s,
		reset_i		=> reset_s,
		refresh_i	=> '1',
		-- Static RAM bus
		addr_i		=> sdram_addr_s,
		data_i		=> ram_data_to_s,
		data_o		=> ram_data_from_s,
		cs_i			=> ram_ce_s,
		oe_i			=> ram_oe_s,
		we_i			=> ram_we_s,
		-- SD-RAM ports
		mem_cke_o	=> sdram_cke_o,
		mem_cs_n_o	=> sdram_cs_n_o,
		mem_ras_n_o	=> sdram_ras_n_o,
		mem_cas_n_o	=> sdram_cas_n_o,
		mem_we_n_o	=> sdram_we_n_o,
		mem_udq_o	=> sdram_dqmh_o,
		mem_ldq_o	=> sdram_dqml_o,
		mem_ba_o		=> sdram_ba_o,
		mem_addr_o	=> sdram_addr_o,
		mem_data_io	=> sdram_dq_io
	);

	-- Keyboard PS/2
	keyb: entity work.keyboard
	port map (
		clock_i			=> clock_3m_s,
		reset_i			=> reset_s,
		-- MSX
		rows_coded_i	=> rows_s,
		cols_o			=> cols_s,
		keymap_addr_i	=> keymap_addr_s,
		keymap_data_i	=> keymap_data_s,
		keymap_we_i		=> keymap_we_s,
		-- LEDs
		led_caps_i		=> caps_en_s,
		-- PS/2 interface
		ps2_clk_io		=> ps2_clk_io,
		ps2_data_io		=> ps2_dat_io,
		--
		reset_o			=> soft_reset_k_s,
		por_o				=> soft_por_s,
		reload_core_o	=> open,
		extra_keys_o	=> extra_keys_s
	);

	-- Audio
	audio: entity work.Audio_DAC
	port map (
		clock_i			=> clock_master_s,
		reset_i			=> reset_s,
		audio_scc_i		=> audio_scc_s,
		audio_psg_i		=> audio_psg_s,
		beep_i			=> beep_s,
		dac_out_o		=> dac_s
	);

	-- VRAM
	vram: entity work.spram
	generic map (
		addr_width_g => 14,
		data_width_g => 8
	)
	port map (
		clk_i		=> clock_master_s,
		we_i		=> vram_we_s,
		addr_i	=> vram_addr_s,
		data_i	=> vram_di_s,
		data_o	=> vram_do_s
	);

	-- Tape In
	tapein: entity work.tlc549
	generic map (
		frequency_g			=> 21,
		sample_cycles_g	=> 28
	)
	port map (
		clock_i	 	=> clock_master_s,
		reset_i	 	=> reset_s,
		clock_o		=> open,
		data_o		=> tapein_s,
		adc_data_i	=> adc_data_i,
		adc_cs_n_o	=> adc_cs_n_o,
		adc_clk_o	=> adc_clock_o
	);

	-----------------------------------------------------------------------------
	-- SNES Gamepads
	-----------------------------------------------------------------------------
	snespads_b : entity work.snespad
	generic map (
		num_pads_g			=> 1,
		reset_level_g		=> 1,
		button_level_g		=> 0,
		clocks_per_6us_g	=> 128					-- 6us = 128 ciclos de 21.477MHz
	)
	port map (
		clk_i					=> clock_master_s,
		reset_i				=> reset_s,
		pad_clk_o			=> pad_clk_o,
		pad_latch_o			=> pad_latch_o,
		pad_data_i(0)		=> pad_data_i,
		but_a_o(0)			=> but_a_s,
		but_b_o(0)			=> but_b_s,
		but_x_o(0)			=> but_x_s,
		but_y_o(0)			=> but_y_s,
		but_start_o(0)		=> but_start_s,
		but_sel_o(0)		=> but_sel_s,
		but_tl_o(0)			=> but_tl_s,
		but_tr_o(0)			=> but_tr_s,
		but_up_o(0)			=> but_up_s,
		but_down_o(0)		=> but_down_s,
		but_left_o(0)		=> but_left_s,
		but_right_o(0)		=> but_right_s
	);

	-- Glue logic

	-- Power-on counter
	process (clock_master_s)
	begin
		if rising_edge(clock_master_s) then
			if por_cnt_s /= 0 then
				por_cnt_s <= por_cnt_s - 1;
			end if;
		end if;
	end process;

	por_clock_s	<= '1'	when por_cnt_s /= 0																else '0';
	por_s			<= '1'	when por_cnt_s /= 0  or soft_por_s = '1'   or keys_n_i(3) = '0'	else '0';
	reset_s		<= '1'	when soft_rst_cnt_s = X"00" or por_s = '1' or keys_n_i(0) = '0'	else '0';

	process(clock_master_s)
	begin
		if rising_edge(clock_master_s) then
			if reset_s = '1' or por_s = '1' then
				soft_rst_cnt_s	<= X"FF";
			elsif (soft_reset_k_s = '1' or soft_reset_s_s = '1') and soft_rst_cnt_s /= X"00" then
				soft_rst_cnt_s <= soft_rst_cnt_s - 1;
			end if;
		end if;
	end process;

	-- Audio
	audio_dac_l_o	<= dac_s;
	audio_dac_r_o	<= dac_s;
	buzzer_o			<= beep_s;

	-- Tape In (via ADC)
	process (clock_master_s)
		constant HYST_C  : integer := 4;
		constant LEVEL_C : integer := 40;
	begin
		if rising_edge(clock_master_s) then
			if    ear_s = '1' and tapein_s < LEVEL_C - HYST_C then
				ear_s <= '0';
			elsif ear_s = '0' and tapein_s > LEVEL_C + HYST_C then
				ear_s <= '1';
			end if;
		end if;
	end process;

	-- VGA Output
	vga_r_o	<= rgb_r_s & '0';
	vga_g_o	<= rgb_g_s & "00";
	vga_b_o	<= rgb_b_s & '0';
	vga_hs_o	<= rgb_hsync_n_s;
	vga_vs_o	<= rgb_vsync_n_s;

	-- SD
	sd_cs_n_o <= sd_cs_n_s;

	-- DEBUG
	leds_n_o(0) <= sd_cs_n_s;
	leds_n_o(1) <= not ntsc_pal_s;
	leds_n_o(2) <= not vga_en_s;
	leds_n_o(3) <= not turbo_on_s;

end architecture;
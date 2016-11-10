--
-- exp_slot.vhd 
--  Rev 1.0
--
-- Copyright (c) 2013 Fabio Belavenuto <belavenuto@gmail.com>
-- All rights reserved.
-- 
-- Redistribution and use of this source code or any derivative works, are 
-- permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice, 
--      this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright 
--      notice, this list of conditions and the following disclaimer in the 
--      documentation and/or other materials provided with the distribution.
-- 3. Redistributions may not be sold, nor may they be used in a commercial 
--      product or activity without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
-- OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- Implementa um expansor de slots padrao.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.and_reduce;

entity exp_slot is
	port(
		reset_i			: in  std_logic;
		ipl_en_i			: in  std_logic;
		addr_i			: in  std_logic_vector(15 downto 0);
		data_i			: in  std_logic_vector(7 downto 0);
		data_o			: out std_logic_vector(7 downto 0);
		has_data_o		: out std_logic;
		sltsl_n_i		: in  std_logic;
		rd_n_i			: in  std_logic;
		wr_n_i			: in  std_logic;
		expsltsl_n_o	: out std_logic_vector(3 downto 0)
	);
end entity;

architecture rtl of exp_slot is

	signal ffff_s		: std_logic;
	signal exp_reg_s	: std_logic_vector(7 downto 0);
	signal exp_sel_s	: std_logic_vector(1 downto 0);
	signal exp_wr_s	: std_logic;
	signal exp_rd_s	: std_logic;

begin

	--
	ffff_s	<= and_reduce(addr_i);
	exp_wr_s <= not (sltsl_n_i or wr_n_i or not ffff_s);
	exp_rd_s <= not (sltsl_n_i or rd_n_i or not ffff_s);

	process(reset_i, ipl_en_i, exp_wr_s)
	begin
		if reset_i = '1' then
			if ipl_en_i = '1' then
				exp_reg_s <= X"FF";
			else
				exp_reg_s <= X"00";
			end if;
		elsif falling_edge(exp_wr_s) then
			exp_reg_s <= data_i;
		end if;
	end process;

	-- Read
	has_data_o	<= exp_rd_s;
	data_o		<= (not exp_reg_s) when exp_rd_s = '1' else
						(others => '1');

	-- subslot mux
	with addr_i(15 downto 14) select exp_sel_s <=
		exp_reg_s(1 downto 0) when "00",
		exp_reg_s(3 downto 2) when "01",
		exp_reg_s(5 downto 4) when "10",
		exp_reg_s(7 downto 6) when others;

	-- Demux 2-to-4
	expsltsl_n_o	<= "1111" when ffff_s = '1' or sltsl_n_i = '1'      else
							"1110" when sltsl_n_i = '0' and exp_sel_s = "00" else
							"1101" when sltsl_n_i = '0' and exp_sel_s = "01" else
							"1011" when sltsl_n_i = '0' and exp_sel_s = "10" else
							"0111";

end architecture;
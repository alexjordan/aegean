-- 
-- Copyright Technical University of Denmark. All rights reserved.
-- This file is part of the T-CREST project.
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
--    1. Redistributions of source code must retain the above copyright notice,
--       this list of conditions and the following disclaimer.
-- 
--    2. Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
-- OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
-- NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
-- THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- The views and conclusions contained in the software and documentation are
-- those of the authors and should not be interpreted as representing official
-- policies, either expressed or implied, of the copyright holder.
-- 


--------------------------------------------------------------------------------
-- A parameterized, inferable, simple dual-port, single-clock block RAM.
--
-- Author: Evangelia Kasapaki
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.noc_defs.all;


entity bram is

generic (
	DATA    : integer := 32;
	ADDR    : integer := 14
);

port (
	clk 	: in std_logic ;
        reset   : in std_logic;
	rd_addr : in std_logic_vector(ADDR-1 downto 0);
	wr_addr : in std_logic_vector(ADDR-1 downto 0);
	wr_data : in std_logic_vector(DATA-1 downto 0);
	wr_ena 	: in std_logic ;
	rd_data : out std_logic_vector(DATA-1 downto 0)
);
end bram;


architecture rtl of bram is
	-- memory
    	type mem_type is array ( (2**ADDR)-1 downto 0 ) of std_logic_vector(DATA-1 downto 0);
	signal mem : mem_type := (others => (others => '0'));

begin

process(clk)
begin
    if reset='1' then
        mem <= (others => (others => '0'));
        rd_data <= (others => '0');
    --end if;
    elsif rising_edge(clk) then

	if wr_ena='1' then
		mem(conv_integer(wr_addr)) <= wr_data;
        end if;
        rd_data <= mem(conv_integer(rd_addr));
    end if;

end process;
 
end rtl;


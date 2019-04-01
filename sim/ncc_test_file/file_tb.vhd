library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity file_tb is
end file_tb;

architecture Behavioral of file_tb is
constant c_CLOCK_PERIOD		: time := 10 ns;
signal   tb_done		: std_logic;
signal   mem_address		: std_logic_vector (15 downto 0) := (others => '0');
signal   tb_rst	                : std_logic := '0';
signal   tb_start		: std_logic := '0';
signal   tb_clk		        : std_logic := '0';
signal   mem_o_data,mem_i_data	: std_logic_vector (7 downto 0);
signal   enable_wire  		: std_logic;
signal   mem_we		        : std_logic;

type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);

file fp : text is in "testcase_random.txt";
shared variable load_case : boolean := true;

impure function readMemFile return ram_type is
  variable line_num : line;
  variable char : character;
  variable word : bit_vector(7 downto 0);
  variable coord: integer;
  variable index: integer;
  variable result : ram_type := (others => (others => '0'));
begin

  readline(fp, line_num); -- Header line
  -- 0: input mask
  readline(fp, line_num);
  read(line_num, result(0));

  -- 1 - 18: P and C coordinates
  index := 0;
  while index < 9 loop
    readline(fp, line_num);
    read(line_num, coord);
    result(1 + 2*index) := std_logic_vector(to_unsigned(coord, 8));
    read(line_num, char); -- ignore
    read(line_num, coord);
    result(2 + 2*index) := std_logic_vector(to_unsigned(coord, 8));
    index := index + 1;
  end loop;

  -- 20: expected mask
  readline(fp, line_num);
  read(line_num, result(20));

  return result;
end readMemFile;

signal RAM: ram_type := (others => (others => '0'));

component project_reti_logiche is
port (
      i_clk         : in  std_logic;
      i_start       : in  std_logic;
      i_rst         : in  std_logic;
      i_data        : in  std_logic_vector(7 downto 0);
      o_address     : out std_logic_vector(15 downto 0);
      o_done        : out std_logic;
      o_en          : out std_logic;
      o_we          : out std_logic;
      o_data        : out std_logic_vector (7 downto 0)
      );
end component project_reti_logiche;


begin
UUT: project_reti_logiche
port map (
          i_clk      	=> tb_clk,
          i_start       => tb_start,
          i_rst      	=> tb_rst,
          i_data    	=> mem_o_data,
          o_address  	=> mem_address,
          o_done      	=> tb_done,
          o_en   	=> enable_wire,
          o_we 		=> mem_we,
          o_data    	=> mem_i_data
          );

p_CLK_GEN : process is
begin
    wait for c_CLOCK_PERIOD/2;
    tb_clk <= not tb_clk;
end process p_CLK_GEN;


MEM : process(tb_clk, tb_rst)
begin
    if rising_edge(tb_clk) then
        if enable_wire = '1' then
            if mem_we = '1' then
                RAM(conv_integer(mem_address))  <= mem_i_data;
                mem_o_data                      <= mem_i_data after 2 ns;
            else
                mem_o_data <= RAM(conv_integer(mem_address)) after 2 ns;
            end if;
        end if;
    elsif load_case = true then
        RAM <= readMemFile;
        load_case := false;
    end if;
end process;


test : process is
begin
  -- reset component
  wait for c_CLOCK_PERIOD;
  tb_rst <= '1';
  wait for c_CLOCK_PERIOD;
  tb_rst <= '0';

  while not endfile(fp) loop
        wait for c_CLOCK_PERIOD;
        load_case := true; -- trigger memory loading from RAM
        wait for c_CLOCK_PERIOD;
        tb_start <= '1';
        wait for c_CLOCK_PERIOD;
        wait until tb_done = '1';
        wait for c_CLOCK_PERIOD;
        tb_start <= '0';
        wait until tb_done = '0';

        -- Check output mask
        assert RAM(19) = RAM(20)
        report "TEST FALLITO" severity failure;
  end loop;

  -- All test cases passed
  assert false report "Simulation Ended!, TEST PASSATO" severity failure;
end process test;

end Behavioral;

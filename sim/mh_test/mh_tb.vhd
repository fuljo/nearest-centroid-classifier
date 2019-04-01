library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity mh_tb is
end mh_tb;

architecture arch of mh_tb is
  constant CLOCK_PERIOD : time := 100 ns;
  signal tb_rst   : std_logic := '0';
  signal tb_clk   : std_logic := '0';
  signal tb_en    : std_logic := '0';
  signal tb_st    : std_logic := '0';
  signal tb_sc    : std_logic := '0';
  signal tb_coord : unsigned(7 downto 0);
  signal tb_dist  : unsigned(8 downto 0);

  component manhattan is
   Port (
    en    : in std_logic;
    clk   : in std_logic;
    rst   : in std_logic;
    st    : in std_logic; -- select point type: point(0) / centroid(1)
    sc    : in std_logic; -- select coordinate name: x(0) / y(1)
    coord : in unsigned(7 downto 0);
    dist  : out unsigned(8 downto 0)
   );
  end component manhattan;

begin

  UUT: manhattan
  port map (
    en => tb_en,
    clk => tb_clk,
    rst => tb_rst,
    st => tb_st,
    sc => tb_sc,
    coord => tb_coord,
    dist => tb_dist
  );

  clk_gen : process
  begin
    wait for CLOCK_PERIOD/2;
    tb_clk <= not tb_clk;
  end process;

  TEST : process
    procedure SET_P(x,y : integer) is
    begin
      wait for CLOCK_PERIOD;
      tb_en <= '1';
      tb_st <= '0';
      tb_sc <= '0';
      tb_coord <= to_unsigned(x, tb_coord'length);
      wait for CLOCK_PERIOD;
      tb_st <= '0';
      tb_sc <= '1';
      tb_coord <= to_unsigned(y, tb_coord'length);
    end SET_P;

    procedure SET_C(x,y : integer) is
    begin
      wait for CLOCK_PERIOD;
      tb_en <= '1';
      tb_st <= '1';
      tb_sc <= '0';
      tb_coord <= to_unsigned(x, tb_coord'length);
      wait for CLOCK_PERIOD;
      tb_st <= '1';
      tb_sc <= '1';
      tb_coord <= to_unsigned(y, tb_coord'length);
    end SET_C;
  begin
    -- reset
    wait for CLOCK_PERIOD;
    tb_rst <= '1';
    wait for CLOCK_PERIOD;
    tb_rst <= '0';
    tb_en <= '1';

    -- 1. P coincides with C
    SET_P(255, 255);
    SET_C(255, 255);
    wait for CLOCK_PERIOD;
    tb_en <= '0';
    assert tb_dist = to_unsigned(0, tb_dist'length)
    report "CASE 01: failed" severity failure;

    -- 2. longest distance
    SET_P(0, 0);
    wait for CLOCK_PERIOD;
    tb_en <= '0';
    assert tb_dist = to_unsigned(510, tb_dist'length)
    report "CASE 02: failed" severity failure;

    -- 3. dx, dy < 0
    SET_P(120, 60);
    SET_C(190, 65);
    wait for CLOCK_PERIOD;
    tb_en <= '0';
    assert tb_dist = to_unsigned(75, tb_dist'length)
    report "CASE 03: failed" severity failure;

    -- 4. dx < 0, dy > 0
    SET_C(190, 50);
    wait for CLOCK_PERIOD;
    tb_en <= '0';
    assert tb_dist = to_unsigned(80, tb_dist'length)
    report "CASE 04: failed" severity failure;

    -- 5. dx < 0, dy > 0
    SET_C(20, 80);
    wait for CLOCK_PERIOD;
    tb_en <= '0';
    assert tb_dist = to_unsigned(120, tb_dist'length)
    report "CASE 05: failed" severity failure;

    -- 6. dx < 0, dy > 0
    SET_C(20, 20);
    wait for CLOCK_PERIOD;
    tb_en <= '0';
    assert tb_dist = to_unsigned(140, tb_dist'length)
    report "CASE 06: failed" severity failure;

    -- 7. Keeps previous state if enable = 0
    wait for CLOCK_PERIOD;
    tb_en <= '0';
    tb_coord <= to_unsigned(15, tb_coord'length);
    wait for 2*CLOCK_PERIOD;
    assert tb_dist = to_unsigned(140, tb_dist'length)
    report "CASE 05: failed" severity failure;
  end process;

end architecture;
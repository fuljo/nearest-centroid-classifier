library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity nk_tb is
end nk_tb;

architecture arch of nk_tb is
  constant CLOCK_PERIOD : time := 100 ns;
  signal tb_rst   : std_logic := '0';
  signal tb_clk   : std_logic := '0';
  signal tb_en    : std_logic := '0';
  signal tb_index : unsigned(2 downto 0);
  signal tb_mask  : std_logic_vector(7 downto 0);
  signal tb_dist  : unsigned(8 downto 0);

  component nearest_keeper is
    port (
      en: in std_logic; -- input enable signal
      clk: in std_logic; -- clock signal
      rst: in std_logic; -- reset signal
      index: in unsigned(2 downto 0); -- index of current centroid
      dist: in unsigned(8 downto 0); -- distance of the current centroid
      mask: out std_logic_vector(7 downto 0) -- nearest centroids mask
     );
   end component nearest_keeper;

begin

  UUT: nearest_keeper
  port map (
    en => tb_en,
    clk => tb_clk,
    rst => tb_rst,
    index => tb_index,
    dist => tb_dist,
    mask => tb_mask
  );

  clk_gen : process
  begin
    wait for CLOCK_PERIOD/2;
    tb_clk <= not tb_clk;
  end process;

  TEST : process
    procedure TEST_CASE
      (index: in integer; dist: in integer;
       mask: in std_logic_vector(7 downto 0)) is
    begin
      tb_index <= to_unsigned(index, tb_index'length);
      tb_dist  <= to_unsigned(dist, tb_dist'length);
      wait for CLOCK_PERIOD;
      assert tb_mask <= mask
      report "FAILURE" severity failure;
    end TEST_CASE;
  begin
    -- reset
    wait for CLOCK_PERIOD;
    tb_rst <= '1';
    wait for CLOCK_PERIOD;
    tb_rst <= '0';
    assert tb_mask = "00000000"
    report "INIT ERROR" severity failure;

    tb_en <= '1';

    -- Sequence
    TEST_CASE(0, 255 + 255, "00000001");
    TEST_CASE(1, 255, "00000010");
    TEST_CASE(2, 200, "00000100");
    TEST_CASE(3, 200, "00001100");
    TEST_CASE(4, 250, "00001100");
    tb_en <= '0';
    TEST_CASE(5, 000, "00001100"); -- Disabled
    tb_en <= '1';
    TEST_CASE(6, 200, "01001100");
    TEST_CASE(7, 000, "10000000");
  end process;

end architecture;
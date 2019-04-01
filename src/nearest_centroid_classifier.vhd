----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Alessandro Fulgini
--
-- Create Date: 02/06/2019 07:50:35 PM
-- Design Name: Nearest centroid classifier
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: Prova finale di Reti Logiche A.A. 2018/19
-- Target Devices: xc7a200tfbg484-1
-- Tool Versions: 2018.2, 2018.3
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 1.0 - First architecture
-- Revision 1.1 - Read from memory on falling edge
-- Additional Comments:
--
----------------------------------------------------------------------------------
-- Copyright (c) 2019 Alessandro Fulgini All Rights Reserved.


-- ##########################
-- MANHATTAN (MH) COMPONENT
-- ##########################
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity manhattan is
 Port (
  en    : in std_logic;
  clk   : in std_logic;
  rst   : in std_logic;
  st    : in std_logic; -- select point type: point(0) / centroid(1)
  sc    : in std_logic; -- select coordinate name: x(0) / y(1)
  coord : in unsigned(7 downto 0);
  dist  : out unsigned(8 downto 0)
 );
end manhattan;

architecture Behavioral of manhattan is
  constant x, p : std_logic := '0';
  constant y, c : std_logic := '1';
  signal xp, yp, xc, yc : unsigned(7 downto 0);
begin
  -- Registries
  xp_reg : process(clk, rst, en, st, sc, coord)
  begin
    if rst = '1' then
      xp <= (others => '0'); -- reset value
    elsif falling_edge(clk) then
      if st = p and sc = x and en = '1' then
        xp <= coord; -- save input coord.
      else
        xp <= xp; -- keep current value
      end if;
    end if;
  end process;

  yp_reg : process(clk, rst, st, sc, coord)
  begin
    if rst = '1' then
      yp <= (others => '0');
    elsif falling_edge(clk) then
      if st = p and sc = y and en = '1' then
        yp <= coord;
      else
        yp <= yp;
      end if;
    end if;
  end process;

  xc_reg : process(clk, rst, st, sc, coord)
  begin
    if rst = '1' then
      xc <= (others => '0');
    elsif falling_edge(clk) then
      if st = c and sc = x and en = '1' then
        xc <= coord;
      else
        xc <= xc;
      end if;
    end if;
  end process;

  yc_reg : process(clk, rst, st, sc, coord)
  begin
    if rst = '1' then
      yc <= (others => '0');
    elsif falling_edge(clk) then
      if st = c and sc = y and en = '1' then
        yc <= coord;
      else
        yc <= yc;
      end if;
    end if;
  end process;

  calc_dist : process(en, xp, yp, xc, yc)
  begin
    dist <=
      to_unsigned(
        abs(to_integer(xc) - to_integer(xp))
        +
        abs(to_integer(yc) - to_integer(yp))
      , dist'length);
  end process;

end Behavioral;

-- ###############################
-- NEAREST KEEPER (NK) COMPONENT
-- ###############################
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity nearest_keeper is
  port (
    en: in std_logic; -- input enable signal
    clk: in std_logic; -- clock signal
    rst: in std_logic; -- reset signal
    index: in unsigned(2 downto 0); -- index of current centroid
    dist: in unsigned(8 downto 0); -- distance of the current centroid
    mask: out std_logic_vector(7 downto 0) -- nearest centroids mask
   );
end nearest_keeper;

architecture Behavioral of nearest_keeper is
  signal mask_curr, mask_next: std_logic_vector(7 downto 0);
  signal min_dist, min_dist_next: unsigned(8 downto 0);
begin
  mask <= mask_curr;

  mask_reg : process(clk, rst, en, mask_next)
  begin
    if rst = '1' then
      mask_curr <= (others => '0');
    elsif rising_edge(clk) and en = '1' then
      mask_curr <= mask_next;
    end if;
  end process;

  min_dist_reg : process(clk, rst, en, min_dist_next)
  begin
    if rst = '1' then
      min_dist <= (others => '1'); -- set maximum distance
    elsif rising_edge(clk) and en = '1' then
      min_dist <= min_dist_next;
    end if;
  end process;

  upd_mask : process(index, dist, min_dist, mask_curr)
  begin
    -- copy previous data
    mask_next <= mask_curr;

    -- update
    if dist <= min_dist then
      if dist < min_dist then
        -- reset mask
        mask_next <= (others => '0');
      end if;
      -- set '1' on the newly found nearest centroid
      mask_next(to_integer(index)) <= '1';
    end if;
  end process;

  upd_dist : process(dist, min_dist)
  begin
    if dist < min_dist then
      min_dist_next <= dist;
    else
      min_dist_next <= min_dist;
    end if;
  end process;

end Behavioral;

-- #######################
-- MAIN (NCC) COMPONENT
-- #######################
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
  port (
   i_clk : in std_logic;
   i_start : in std_logic;
   i_rst : in std_logic;
   i_data : in std_logic_vector(7 downto 0);
   o_address : out std_logic_vector(15 downto 0);
   o_done : out std_logic;
   o_en : out std_logic;
   o_we : out std_logic;
   o_data : out std_logic_vector (7 downto 0)
   );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
  -- control signals
  signal clk, rst : std_logic;

  -- machine state
  type state_t is (
    IDLE, pick_mask,
    load_mask, load_xp, load_yp,
    pick_c, load_xc, load_yc,
    calculate_dist, write_mask, done
  );

  signal state, state_next : state_t := IDLE;

  -- constants for manhattan
  constant x, p : std_logic := '0';
  constant y, c : std_logic := '1';

  -- input mask register
  signal input_mask : std_logic_vector(7 downto 0);

  -- current centroid index register
  signal index, index_next : unsigned(2 downto 0) := (others => '0');

  -- signals for manhattan component
  signal mh_en : std_logic := '0';
  signal mh_st, mh_sc : std_logic;
  signal mh_coord : unsigned(7 downto 0);

  -- signals for nearesk keeper component
  signal nk_en : std_logic := '0';
  signal nk_rst : std_logic;
  signal nk_mask : std_logic_vector(7 downto 0);

  -- interconnecting signals
  signal dist : unsigned(8 downto 0);

  -- components
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
  -- component instances
  mh: manhattan
  port map (
    en => mh_en,
    clk => clk,
    rst => rst,
    st => mh_st,
    sc => mh_sc,
    coord => mh_coord,
    dist => dist
  );

  nk: nearest_keeper
  port map (
    en => nk_en,
    clk => clk,
    rst => nk_rst,
    index => index,
    dist => dist,
    mask => nk_mask
  );

  -- map external ports
  clk <= i_clk;
  rst <= i_rst;
  mh_coord <= unsigned(i_data);

  -- State register
  state_reg : process(clk, rst, state_next)
  begin
    if rst = '1' then
      state <= IDLE;
    elsif rising_edge(clk) then
      state <= state_next;
    end if;
  end process;

  -- Centroid index register
  index_reg : process(clk, rst, index_next)
  begin
    if rst = '1' then
      index <= (others => '0');
    elsif rising_edge(clk) then
      index <= index_next;
    end if;
  end process;

  -- Mask register
  input_mask_reg : process(clk, rst, state)
  begin
    if rst = '1' then
      input_mask <= (others => '0');
    elsif falling_edge(clk) and state = load_mask then
      -- load the mask
      input_mask <= i_data;
    end if;
  end process;

  done_reg : process(clk, rst, state_next)
  begin
    if rst = '1' then
      o_done <= '0';
    elsif rising_edge(clk) then
      if state_next = done then
        o_done <= '1';
      else
        o_done <= '0';
      end if;
    end if;
  end process;

  -- calculate state and index
  FSM : process(state, index, i_start, input_mask)
  begin
    -- default values for signals
    index_next <= index;

    case( state ) is

      when IDLE =>
        -- wait for start signal
        if i_start = '1' then
          state_next <= pick_mask;
        else
          state_next <= IDLE;
        end if;

      when pick_mask =>
        state_next <= load_mask;

      when load_mask =>
        -- mask is saved by register in its process
        state_next <= load_xp;

      when load_xp =>
        state_next <= load_yp;

      when load_yp =>
        -- set index of first centroid
        index_next <= (others => '0');

        state_next <= pick_c;

      when pick_c =>
        if input_mask(to_integer(index)) = '1' then
          -- valid centroid
          state_next <= load_xc;
        elsif index /= 7 then
          -- pick next centroid
          index_next <= index + 1;
          state_next <= pick_c;
        else
          -- reached last centroid
          state_next <= write_mask;
        end if;

      when load_xc =>
        state_next <= load_yc;

      when load_yc =>
        state_next <= calculate_dist;

      when calculate_dist =>
        if index /= 7 then
          -- go to next centroid
          index_next <= index + 1;
          state_next <= pick_c;
        else
          -- go to write result
          state_next <= write_mask;
        end if;

      when write_mask =>
        state_next <= done;

      when done =>
        -- wait for start signal to turn off
        if i_start = '0' then
          state_next <= IDLE;
        else
          state_next <= done;
        end if;

      when others =>
        state_next <= IDLE;
    end case;
  end process;

  -- calculate inputs for components
  calc_mh_inputs : process(state)
  begin
    case( state ) is

      when load_xp =>
        -- save x_P
        mh_en <= '1';
        mh_st <= p;
        mh_sc <= x;

      when load_yp =>
        -- save y_P
        mh_en <= '1';
        mh_st <= p;
        mh_sc <= y;

      when load_xc =>
        -- save x_P
        mh_en <= '1';
        mh_st <= c;
        mh_sc <= x;

      when load_yc =>
        -- save y_P
        mh_en <= '1';
        mh_st <= c;
        mh_sc <= y;

      when others =>
        mh_en <= '0';
        mh_st <= '-';
        mh_sc <= '-';
    end case;
  end process;

  -- always reset output mask and min_dist before starting a new computation
  nk_rst <= rst or not i_start;

  calc_nk_inputs : process(state)
  begin
    case( state ) is
      when calculate_dist =>
        -- all the values are set to calculate the manhattan distance
        -- so the output of the manhattan component is valid and
        -- will be handled by the nearest keeper
        nk_en <= '1';

      when others =>
        nk_en <= '0';
    end case;
  end process;

  mem_read_write : process(state, index)
  begin
    -- calculate en, we, address signals
    case( state ) is
      when pick_mask =>
        -- request input mask (mem 0)
        o_en <= '1';
        o_we <= '0';
        o_address <= (others => '0');

      when load_mask =>
        -- request x_P (mem 17)
        o_en <= '1';
        o_we <= '0';
        o_address <= std_logic_vector(to_unsigned(17, o_address'length));

      when load_xp =>
        -- request y_P (mem 18)
        o_en <= '1';
        o_we <= '0';
        o_address <= std_logic_vector(to_unsigned(18, o_address'length));

      when pick_c =>
        -- request x of current centroid
        o_en <= '1';
        o_we <= '0';
        o_address <= std_logic_vector(resize(2*index+1, o_address'length));

      when load_xc =>
        -- request y of current centroid
        o_en <= '1';
        o_we <= '0';
        o_address <= std_logic_vector(resize(2*index+2, o_address'length));

      when write_mask =>
        -- write the current mask to memory
        o_en <= '1';
        o_we <= '1';
        o_address <= std_logic_vector(to_unsigned(19, o_address'length));
        -- o_data is calculated later

      when others =>
        o_we <= '0';
        o_en <= '0';
        o_address <= (others => '-');
    end case;
  end process;

  -- the only data to write out is nk_mask
  o_data <= nk_mask;

end Behavioral;

------------------------------------------------------------------------------
-- vga_fsl - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          vga_fsl
-- Version:           1.00.a
-- Description:       Example FSL core (VHDL).
-- Date:              Mon Apr  7 21:24:28 2014 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------------
--
--
-- Definition of Ports
-- FSL_Clk             : Synchronous clock
-- FSL_Rst           : System reset, should always come from FSL bus
-- FSL_S_Clk       : Slave asynchronous clock
-- FSL_S_Read      : Read signal, requiring next available input to be read
-- FSL_S_Data      : Input data
-- FSL_S_CONTROL   : Control Bit, indicating the input data are control word
-- FSL_S_Exists    : Data Exist Bit, indicating data exist in the input FSL bus
--
-------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Entity Section
------------------------------------------------------------------------------

entity vga_fsl is
	port 
	(
		vga_clk : in std_logic;
		hsync: out  std_logic;
		vsync: out  std_logic;
		rgb:   out std_logic_vector(7 downto 0);
		-- DO NOT EDIT BELOW THIS LINE ---------------------
		-- Bus protocol ports, do not add or delete. 
		FSL_Clk	: in	std_logic;
		FSL_Rst	: in	std_logic;
		FSL_S_Clk	: in	std_logic;
		FSL_S_Read	: out	std_logic;
		FSL_S_Data	: in	std_logic_vector(0 to 31);
		FSL_S_Control	: in	std_logic;
		FSL_S_Exists	: in	std_logic
		-- DO NOT EDIT ABOVE THIS LINE ---------------------
	);

attribute SIGIS : string; 
attribute SIGIS of FSL_Clk : signal is "Clk"; 
attribute SIGIS of FSL_S_Clk : signal is "Clk"; 
attribute SIGIS of vga_clk : signal is "Clk";
end vga_fsl;

------------------------------------------------------------------------------
-- Architecture Section
------------------------------------------------------------------------------

-- In this section, we povide an example implementation of ENTITY vga_fsl
-- that Read all inputs and add each input to the contents of register 'sum' which
-- acts as an accumulator
--
-- You will need to modify this example or implement a new architecture for
-- ENTITY vga_fsl to implement your coprocessor

architecture EXAMPLE of vga_fsl is

	component vga_top is
    generic (OBJECT_SIZE : natural := 10);
    port (
      clk, reset: in std_logic;
      wall_x3 : in std_logic_vector(0 to OBJECT_SIZE-1);
      hole_y3 : in std_logic_vector(0 to OBJECT_SIZE-1);
		wall_x2 : in std_logic_vector(0 to OBJECT_SIZE-1);
      hole_y2 : in std_logic_vector(0 to OBJECT_SIZE-1);
		wall_x1 : in std_logic_vector(0 to OBJECT_SIZE-1);
      hole_y1 : in std_logic_vector(0 to OBJECT_SIZE-1);
      wall_x0 : in std_logic_vector(0 to OBJECT_SIZE-1);
      hole_y0 : in std_logic_vector(0 to OBJECT_SIZE-1);
      bird_x : in std_logic_vector(0 to OBJECT_SIZE-1);
      bird_y : in std_logic_vector(0 to OBJECT_SIZE-1);
		
		bird1_x : in std_logic_vector(0 to OBJECT_SIZE-1);
      bird1_y : in std_logic_vector(0 to OBJECT_SIZE-1);
		bird2_x : in std_logic_vector(0 to OBJECT_SIZE-1);
      bird2_y : in std_logic_vector(0 to OBJECT_SIZE-1);
      hsync, vsync: out  std_logic;
      rgb: out std_logic_vector(7 downto 0)
	);
	end component;


   -- This game has two objects and position will not exceed 1023
   -- because VGA screen resolution is 640x480.
   constant OBJECT_SIZE : natural := 10; -- max. coordinate value is 1024
   subtype OBJECT is STD_LOGIC_VECTOR (0 to OBJECT_SIZE-1);
   constant OBJECTS_SIZE : natural := 14; --[][][][][] 
   type OBJECTS is array (0 to OBJECTS_SIZE-1) of OBJECT;  
   signal objects_array, objects_array_todisplay : OBJECTS;

   -- This is used to signal loading the objects for display
   signal objects_done : std_logic;
   
   -- Total number of input data.
   constant NUMBER_OF_INPUT_WORDS  : natural := 14;

   type STATE_TYPE is (Idle, Read_Inputs);

   signal state        : STATE_TYPE;

   -- Counters to store the number inputs read
   signal nr_of_reads  : natural range 0 to NUMBER_OF_INPUT_WORDS - 1;

begin
   -- CAUTION:
   -- The sequence in which data are read in should be
   -- consistent with the sequence they are written in the
   -- driver's vga_fsl.c file

   FSL_S_Read  <= FSL_S_Exists   when state = Read_Inputs   else '0';
   The_SW_accelerator : process (FSL_Clk) is
   begin  -- process The_SW_accelerator
    if FSL_Clk'event and FSL_Clk = '1' then     -- Rising clock edge
      if FSL_Rst = '1' then               -- Synchronous reset (active high)
        -- CAUTION: make sure your reset polarity is consistent with the
        -- system reset polarity
        state        <= Idle;
        objects_array <= (OTHERS => (OTHERS => '0'));
        objects_done <= '0';
        nr_of_reads  <= 0;
      else
        case state is
          when Idle =>
            if (FSL_S_Exists = '1') then
              state       <= Read_Inputs;
              nr_of_reads <= NUMBER_OF_INPUT_WORDS - 1;
			  objects_array <= (OTHERS => (OTHERS => '0'));
              objects_done <= '0';
            end if;

          when Read_Inputs =>
            if (FSL_S_Exists = '1') then
              -- Coprocessor function (Adding) happens here
              objects_array(nr_of_reads) <= FSL_S_Data (22 to 31);
              if (nr_of_reads = 0) then
                objects_done <= '1';
                state        <= Idle;
              else
                objects_done <= '0';  
                nr_of_reads <= nr_of_reads - 1;
              end if;
            end if;

        end case;
      end if;
    end if;
   end process The_SW_accelerator;
   
      -- Process to copy object positions to buffer that gets displayed...
   COPY_OBJECTS: process (FSL_Clk) is
   begin
    if FSL_Clk'event and FSL_Clk = '1' then     -- Rising clock edge
      if FSL_Rst = '1' then               -- Synchronous reset (active high)
        -- CAUTION: make sure your reset polarity is consistent with the
        -- system reset polarity
        objects_array_todisplay <= (OTHERS => (OTHERS => '0'));
      elsif objects_done = '1' then
        objects_array_todisplay <= objects_array;
      end if;
    end if;
   end process;

   -- Instance the VGA component
   GAME_TOP_U1: vga_top generic map (OBJECT_SIZE=>OBJECT_SIZE)
   port map (
    clk => vga_clk,
    reset => FSL_Rst,
	 bird2_x => objects_array_todisplay(13),
    bird2_y => objects_array_todisplay(12),
	 bird1_x => objects_array_todisplay(11),
    bird1_y => objects_array_todisplay(10),
	 wall_x3 => objects_array_todisplay(9),
	 hole_y3 => objects_array_todisplay(8),
	 wall_x2 => objects_array_todisplay(7),
	 hole_y2 => objects_array_todisplay(6),
	 wall_x1 => objects_array_todisplay(5),
	 hole_y1 => objects_array_todisplay(4),
    wall_x0 => objects_array_todisplay(3),
    hole_y0 => objects_array_todisplay(2),
    bird_x => objects_array_todisplay(1),
    bird_y => objects_array_todisplay(0),
    hsync => hsync,
    vsync => vsync,
    rgb => rgb
    );
   
end architecture EXAMPLE;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all; -- allows the use of logarithms


-- This entity describes a paramtereizable register bank made up of
--  n-bit registers (DFFs) that can take any two inputs vectors 
--  with a single write but dual read (read both output vectors at
--  once)?


-- system takes an input data vector of n-bits (data_size) which can be stored
--  in N register banks (log2(num_reg)) via a write enable function. Output from
--  either register are controlled by multiplexors with control signals from further
--  input vectors (rreg_ A or B).




entity param_reg_bank is
    generic ( data_size : NATURAL := 16; -- default bus size
              num_regs : NATURAL := 8); -- default number of registers
    Port ( -- control signals
           clk, rst, wen : in STD_LOGIC; -- clock, reset, write enable - single bit inputs
           wreg : in UNSIGNED(log2(num_regs)-1 downto 0); -- vector points to register being written to
           r_reg_A : in UNSIGNED(log2(num_regs)-1 downto 0); -- read reg bank A -- controls mux 1 for data output (read)
           r_reg_B : in UNSIGNED(log2(num_regs)-1 downto 0); -- read reg bank B -- controls mux 2 for data output (read)
           -- I/O vectors
           D_in : in STD_LOGIC_VECTOR (data_size - 1 downto 0); -- data input vector
           D_out_A : out STD_LOGIC_VECTOR (data_size -1 downto 0); -- data output vector from mux 1 (reg bank A)
           D_out_B : out STD_LOGIC_VECTOR (data_size -1 downto 0) -- data output vector from mux 2 (reg bank B)
    );
end param_reg_bank;


architecture Behavioral of param_reg_bank is
   
    -- split large internal vector in vector array:
    type reg_bank_type is array (num_regs-1 downto 0) of STD_LOGIC_VECTOR(data_size-1 downto 0);
    signal DO: reg_bank_type;
    
    -- internal signal for the write enable combinational logic
    signal wen_reg : UNSIGNED(num_regs-1 downto 0); -- not log2(x) -1 due to for-generate excluding 0
begin
-- generate register bank of [num_reg] registers of bus size [data_size] bits
generic_reg_bank : for i in 1 to num_regs-1 generate -- generate [num_reg] registers
    generic_reg : entity work.n_bit_reg  
        generic map( size => data_size) -- of size [data_size] bits
        port map(
            clk => clk, -- link control signals
            rst => rst,
            wen => wen_reg(i), -- write enable gets register select vector(i) when write is enabled
            D => D_in, -- every register gets the input vector D_in
            Q => DO(i)); -- Output gets vector DO of [data_size] bits
        wen_reg(i) <= '1' when (wen = '1' AND wreg = i) else '0';
end generate;
--combinational logic
DO(0) <= (others => '0'); -- ground register 0 for 0-bit generation
D_out_A <= DO(to_integer(r_reg_A)); -- D_out_A is controlled by value of r_reg_A
D_out_B <= DO(to_integer(r_reg_B)); -- same principle for B
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-- This entity describes a parameterizable register that uses D-type flip flops 
--  to store and return n-bits.
entity n_bit_reg is
    generic (size: NATURAL := 32); -- default bus size 
    Port ( clk, rst, wen : in STD_LOGIC; -- clock, reset, write enable - single bit inputs
           D : in STD_LOGIC_VECTOR (size-1 downto 0); -- input vector
           Q : out STD_LOGIC_VECTOR (size-1 downto 0)); -- output vector
end n_bit_reg;


architecture Behavioral of n_bit_reg is
begin
    REG: process (clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then -- synchronised reset
                Q <= (others => '0'); 
            elsif (wen = '1') then
                Q <= D; -- output = input if write enabled
            end if;
        end if;
    end process REG;
end Behavioral;

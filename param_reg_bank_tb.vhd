library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.ALL; -- allows use of logarithms


entity param_reg_bank_tb is
-- empty entity for test bench
end param_reg_bank_tb;


architecture Behavioral of param_reg_bank_tb is
    --clock period
    constant clk_period : time := 10ns;
    --generics
    constant num_regs  : NATURAL := 8; -- 8 registers
    constant data_size : NATURAL := 16; -- 16-bits
    -- inputs
    signal clk, rst, wen : STD_LOGIC;
    signal wreg    : UNSIGNED(log2(num_regs)-1 downto 0); -- register select/addressing vector thus log2 of number of registers
    signal r_reg_A : UNSIGNED(log2(num_regs)-1 downto 0); -- mux select for data out A (read reg bank A)
    signal r_reg_B : UNSIGNED(log2(num_regs)-1 downto 0); -- mux select for data out B (read reg bank B)
    signal D_in    : STD_LOGIC_VECTOR (data_size -1 downto 0); -- Data input
    -- outputs
    signal D_out_A : STD_LOGIC_VECTOR (data_size -1 downto 0); -- Data output from mux A
    signal D_out_B : STD_LOGIC_VECTOR (data_size -1 downto 0); -- Data output from mux B
    
type test_vector is record
    wreg_TV, r_reg_A_TV, r_reg_B_TV : UNSIGNED (log2(num_regs)-1 downto 0); -- 3 bits
    D_in_TV, D_out_A_TV, D_out_B_TV : STD_LOGIC_VECTOR (data_size-1 downto 0); -- 16 bits
end record;


type test_vector_array is array
    (NATURAL range<>) of test_vector;
    
constant test_vectors : test_vector_array := (
-- |----------inputs------------|----outputs----| 
-- wreg, r_reg_A, r_reg_B, D_in, D_out_A, D_out_B
   -- Test 0 : Zeroing
   (B"000",B"000",B"000",X"0000",X"0000",X"0000"),
   -- Test 1 : Test input data is not passed to register 0
   (B"000",B"000",B"000",X"FFFF",X"0000",X"0000"), 
   -- Test 2 : Test input data is passed only to enabled register for every register whilst cascading mux select
   (B"001",B"001",B"000",X"FFFF",X"FFFF",X"0000"), -- write FFFF to reg1, read reg1 from A and reg0 from B
   (B"010",B"001",B"010",X"FFF0",X"FFFF",X"FFF0"), -- write FFF0 to reg2, read reg1 from A and reg2 from B
   (B"011",B"011",B"010",X"FF00",X"FF00",X"FFF0"), -- write FF00 to reg3, read reg3 from A and reg2 from B
   (B"100",B"011",B"100",X"F000",X"FF00",X"F000"), -- write F000 to reg4, read reg3 from A and reg4 from B
   (B"101",B"101",B"100",X"AAAA",X"AAAA",X"F000"), -- write AAAA to reg5, read reg5 from A and reg4 from B
   (B"110",B"101",B"110",X"BBAA",X"AAAA",X"BBAA"), -- write BBAA to reg6, read reg5 from A and reg6 from B
   (B"111",B"111",B"110",X"ABBA",X"ABBA",X"BBAA"), -- write ABBA to reg7, read reg7 from A and reg6 from B


   -- Test 3 : Test data can be overwriten 
   (B"001",B"111",B"001",X"F00F",X"ABBA",X"F00F") 
   
    );


begin


UUT : entity work.param_reg_bank
        generic map ( data_size => data_size, -- configure generics
                      num_regs  => num_regs)
        port map ( clk => clk, -- configure ports
                   rst => rst,
                   wen => wen,
                   wreg => wreg,
                   r_reg_A => r_reg_A,
                   r_reg_B => r_reg_B,
                   D_in => D_in,
                   D_out_A => D_out_A,
                   D_out_B => D_out_B);
--clock process
clk_process : process
begin
   clk <= '0';
   wait for clk_period/2;
   clk <= '1';
   wait for clk_period/2;
end process;


-- TESTING STRATEGY lets test this mofo
   -- Test 1 :
--  Test Data in is not passed if 
TEST : process
begin
    wait for 100ns;
    rst <= '1';
    wait for clk_period/2;
    rst <= '0';
    wait for clk_period/2;
    wen <= '0';
    wait for clk_period/2;
    wen <= '1';
    wait for clk_period/2;
    for i in test_vectors'range loop -- loop test vectors
        wreg <= test_vectors(i).wreg_TV; -- assign vector values
        r_reg_A <= test_vectors(i).r_reg_A_TV;
        r_reg_B <= test_vectors(i).r_reg_B_TV;
        D_in <= test_vectors(i).D_in_TV;
        D_out_A <= test_vectors(i).D_out_A_TV;
        D_out_B <= test_vectors(i).D_out_B_TV;
        wait for 20ns; -- allow propergation
        -- assert correct operation
        assert ((D_out_A = test_vectors(i).D_out_A_TV)
            and (D_out_B = test_vectors(i).D_out_B_TV))
        report -- if output doesn't match expected output
            "Test sequence " &
             integer'image(i+1) &
              " failed : " &
             " data out A is "&
              integer'image(to_integer(unsigned(D_out_A))) &
             ", expected : "&
              integer'image(to_integer(unsigned(test_vectors(i).D_out_A_TV))) &
             " data out B is "&
              integer'image(to_integer(unsigned(D_out_B))) &
             ", expected : "&
              integer'image(to_integer(unsigned(test_vectors(i).D_out_B_TV)))
        severity error;
        -- assert failed operation
        assert ((D_out_A /= test_vectors(i).D_out_A_TV) 
            or (D_out_B /= test_vectors(i).D_out_B_TV))
        report -- if output does match expected output
            "Test sequence " &
             integer'image(i+1) &
              " passed." 
        severity note;
        end loop;
    wait;


end process;


end Behavioral;

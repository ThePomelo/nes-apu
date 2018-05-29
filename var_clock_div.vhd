library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity var_clock_div is
port (
    rst : in std_logic;
    clk : in std_logic;
    period: in std_logic_vector(10 downto 0);
    div : out std_logic
);
end var_clock_div;

architecture divider of var_clock_div is
    signal count : std_logic_vector (10 downto 0) := (others => '0');
    signal clk_state : std_logic := '0';
        
begin
    div <= clk_state;
    
    process(count) begin
        if count = "00000000000" then
            clk_state <= '1';
        else
            clk_state <= '0';
        end if;
    end process;
    
    process(clk) begin
        if rst = '1' then
            count <= period;
        elsif rising_edge(clk) then
            if count = "00000000000" then
                count <= period;

            else 
                count <= std_logic_vector( unsigned(count) - 1 );
       
            end if;
        end if;
    end process;
    
end divider;
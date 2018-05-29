library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity apu_clock_div is
port (
    clk : in std_logic;
    div : out std_logic
);
end apu_clock_div;

architecture divider of apu_clock_div is
    signal count : std_logic_vector (7 downto 0) := (others => '0');
    signal clk_state : std_logic := '0';
        
begin
    div <= clk_state;
    
    --125MHz / (1.789773 MHz CPU / 2 for APU) ~ 140 (10001100)
    process(count) begin
        if count = "10001100" then
            clk_state <= '1';
        else
            clk_state <= '0';
        end if;
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if count = "10001100" then
                count <= (0 => '1', others => '0');

            else 
                count <= std_logic_vector( unsigned(count) + 1 );
       
            end if;
        end if;
    end process;
    
end divider;
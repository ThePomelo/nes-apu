library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity envelope is
port(
    en: in std_logic;
    qf_clk: in std_logic;
    constant_volume_flag: in std_logic;
    loop_flag: in std_logic;
    start_flag: in std_logic;
    volume_div_period: in std_logic_vector(3 downto 0);
    volume: out std_logic_vector(3 downto 0)
);
end envelope;

architecture env of envelope is
    signal decay_level: std_logic_vector(3 downto 0) := (others => '0');
    signal period_input: std_logic_vector(10 downto 0);
    signal clk_div_out: std_logic;
    
    component var_clock_div is 
    port (
        rst : in std_logic;
        clk : in std_logic;
        period: in std_logic_vector(10 downto 0);
        div : out std_logic
    );
    end component;
    
begin
    clk_div: var_clock_div port map(clk => qf_clk, rst => start_flag, period => period_input, div => clk_div_out);
    period_input <= "0000000" & volume_div_period;
    
    volume <= decay_level when constant_volume_flag = '0' else
              volume_div_period;

    process(clk_div_out,start_flag) begin
        if start_flag = '1' then
            decay_level <= "1111";
        elsif rising_edge(clk_div_out) and en = '1' then
            if unsigned(decay_level) > 0 or loop_flag = '1' then
                decay_level <= std_logic_vector(unsigned(decay_level)-1);
            end if;
        end if;
    end process;
    
end env;
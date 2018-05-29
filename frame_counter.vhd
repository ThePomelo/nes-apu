library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity frame_counter is
port (
    apu_clk: in std_logic;
    mode: in std_logic;
    interrupt_inhibit: in std_logic;
    quarter_frame, half_frame, frame_interrupt: out std_logic
);
end frame_counter;

architecture divs of frame_counter is
    signal frame_count: std_logic_vector(14 downto 0) := (others => '0');
    signal qf, hf, intr: std_logic := '0';
begin
    quarter_frame <= qf;
    half_frame <= hf;
    frame_interrupt <= intr;
    
    process(frame_count) begin
        if frame_count = "000011101001000" then     --  1864 apu frames
            qf <= '0';
        elsif frame_count = "000111010010000" then     --  3728 apu frames
            qf <= '1';
            hf <= '0';
        elsif frame_count = "001010111011000" then    --  5592 apu frames
            qf <= '0';
        elsif frame_count = "001110100100000" then    --  7456 apu frames
            qf <= '1';
            hf <= '1';
            intr <= '0';
        elsif frame_count = "010010001101000" then   --  9320 apu frames
            qf <= '0';
        elsif frame_count = "010101110110001" then   -- 11185 apu frames
            qf <= '1';
            hf <= '0';
        elsif frame_count = "011001011111001" then   -- 13049 apu frames
            qf <= '0';
            
        -- 4-step mode
        elsif mode = '0' and frame_count = "011101001000010" then    -- 14914 apu frame
            qf <= '1';
            hf <= '1';
            if interrupt_inhibit = '0' then
                intr <= '1';
            end if;
            
        -- 5-step mode
        elsif mode = '1' and frame_count = "100100011010000" then   -- 18640 apu frame
            qf <= '1';
            hf <= '1';
            
        elsif frame_count > "100100011010000" then
            qf <= '0';
            hf <= '0';
            intr <= '0';
        end if; 
    end process;
    
    process(apu_clk) begin
        if rising_edge(apu_clk) then
            
            -- 4-step mode
            if mode = '0' and frame_count = "011101001000010" then    -- 14914 apu frame
                frame_count <= (others => '0');
            
            -- 5-step mode
            elsif mode = '1' and frame_count = "100100011010000" then   -- 18640 apu frame
                frame_count <= (others => '0');
            
            else
                frame_count <= std_logic_vector(unsigned(frame_count)+1);    
--            elsif frame_count > "100100011010000" then
--                frame_count <= (others => '0');
            end if;
            
        end if;
    end process;
end divs;
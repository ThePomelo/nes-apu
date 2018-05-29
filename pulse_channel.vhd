library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pulse_channel is
port (
    apu_clk, hf_clk, qf_clk, en: in std_logic;
    regs: in std_logic_vector(0 to 31);
    output: out std_logic_vector(3 downto 0)
);
end pulse_channel;

architecture pulse of pulse_channel is
    signal duty_cycle : std_logic_vector(1 downto 0) := "10";
    signal length_counter_halt : std_logic := '0';
    signal constant_volume_flag : std_logic := '0';
    signal volume_div_period : std_logic_vector(3 downto 0) := "0100";
    signal sweep: std_logic_vector(7 downto 0) := (others => '0');
    signal timer_period: std_logic_vector(10 downto 0) := "00011111110";
    signal length_counter_load: std_logic_vector(4 downto 0) := "10010";
    
    signal sequence_lut: std_logic_vector(0 to 7);
    signal sequence_index: std_logic_vector(2 downto 0) := "000";
    
    signal timer_count: std_logic_vector(10 downto 0) := (others => '0');
    
    signal lc_en: std_logic;
    signal length_counter: std_logic_vector(7 downto 0) := "00000000";
    signal lc_prev_load: std_logic_vector(4 downto 0) := "10010";
    
    signal volume: std_logic_vector(3 downto 0) := "1111";
    signal env_start_bit: std_logic;

    component envelope is
    port(
        en: in std_logic;
        qf_clk: in std_logic;
        constant_volume_flag: in std_logic;
        loop_flag: in std_logic;
        start_flag: in std_logic;
        volume_div_period: in std_logic_vector(3 downto 0);
        volume: out std_logic_vector(3 downto 0)
    );
    end component;

begin
    env: envelope port map(en => en, qf_clk => qf_clk, constant_volume_flag => constant_volume_flag, loop_flag => length_counter_halt, start_flag => env_start_bit, volume_div_period => volume_div_period, volume => volume);

    --duty_cycle <= regs(0 to 1);
    --length_counter_halt <= regs(2);
    --constant_volume_flag <= regs(3);
    --volume_div_period <= regs(4 to 7);
    --timer_period <= regs(29 to 31) & regs(16 to 23);
    --length_counter_load <= regs(24 to 28);

    sequence_lut <= "00000001" when duty_cycle = "00" else
                    "00000011" when duty_cycle = "01" else
                    "00001111" when duty_cycle = "10" else
                    "11111100" when duty_cycle = "11" else
                    "00000000";
                    
    output <= "0000" when en ='0' or lc_en = '0' or unsigned(timer_period) < 8 else
              volume when sequence_lut(to_integer(unsigned(sequence_index))) = '1' else
              "0000";
              
    lc_en <= '0' when length_counter = "00000000" else
             '1';
             
    process(hf_clk) begin
        if en = '0' then
            length_counter <= (others => '0');
        elsif rising_edge(hf_clk) and en = '1' then
            if length_counter_load /= lc_prev_load then
                lc_prev_load <= length_counter_load;
                env_start_bit <= '1';
            
                case length_counter_load is
                    when "00000"    => length_counter <= "00001010";
                    when "00001"    => length_counter <= "11111110";
                    when "00010"    => length_counter <= "00010100";
                    when "00011"    => length_counter <= "00000010";
                    when "00100"    => length_counter <= "00101000";
                    when "00101"    => length_counter <= "00000100";
                    when "00110"    => length_counter <= "01010000";
                    when "00111"    => length_counter <= "00000110";
                    when "01000"    => length_counter <= "10100000";
                    when "01001"    => length_counter <= "00001000";
                    when "01010"    => length_counter <= "00111100";
                    when "01011"    => length_counter <= "00001010";
                    when "01100"    => length_counter <= "00001110";
                    when "01101"    => length_counter <= "00001100";
                    when "01110"    => length_counter <= "00011010";
                    when "01111"    => length_counter <= "00001110";
                    when "10000"    => length_counter <= "00001100";
                    when "10001"    => length_counter <= "00010000";
                    when "10010"    => length_counter <= "00011000";
                    when "10011"    => length_counter <= "00010010";
                    when "10100"    => length_counter <= "00110000";
                    when "10101"    => length_counter <= "00010100";
                    when "10110"    => length_counter <= "01100000";
                    when "10111"    => length_counter <= "00010110";
                    when "11000"    => length_counter <= "11000000";
                    when "11001"    => length_counter <= "00011000";
                    when "11010"    => length_counter <= "01001000";
                    when "11011"    => length_counter <= "00011010";
                    when "11100"    => length_counter <= "00010000";
                    when "11101"    => length_counter <= "00011100";
                    when "11110"    => length_counter <= "00100000";
                    when "11111"    => length_counter <= "00011110";
                    when others     => length_counter <= "00000000";
                end case;
                
            elsif lc_en = '1' and length_counter_halt = '0' then
                length_counter <= std_logic_vector(unsigned(length_counter)-1);
                env_start_bit <= '0';
            else
                env_start_bit <= '0';
            end if;
        end if;
    end process;
                    
    process(apu_clk) begin
        if rising_edge(apu_clk) and en = '1' and lc_en = '1' then
        
            -- waveform sequencer
            if timer_count = "00000000000" then
                timer_count <= timer_period;
                sequence_index <= std_logic_vector(unsigned(sequence_index)-1);
            else
                timer_count <= std_logic_vector(unsigned(timer_count)-1);
            end if;
        end if;
    end process;

end pulse;


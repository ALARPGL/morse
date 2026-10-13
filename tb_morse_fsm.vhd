library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_morse_fsm is
end entity tb_morse_fsm;

architecture sim of tb_morse_fsm is

    constant CLK_PERIOD : time    := 20 ns;
    constant TB_FREQ    : integer := 1000;
    constant DOT_TIME   : time    := (TB_FREQ / 2) * CLK_PERIOD;
    constant DASH_TIME  : time    := (3 * TB_FREQ / 2) * CLK_PERIOD;

    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';
    signal start : std_logic := '1';
    signal sw    : std_logic_vector(2 downto 0) := "000";
    signal led   : std_logic;

begin

    dut : entity work.morse_fsm
        generic map (CLK_FREQ => TB_FREQ)
        port map (clk => clk, rst => rst, start => start, sw => sw, led => led);

    clk <= not clk after CLK_PERIOD / 2;

    stim : process
    begin
        rst <= '0';
        wait for 100 ns;
        rst <= '1';
        wait for 100 ns;

        sw <= "000";
        wait for 40 ns;
        start <= '0';
        wait for 100 ns;
        start <= '1';
        wait for 70 us;

        sw <= "100";
        wait for 40 ns;
        start <= '0';
        wait for 100 ns;
        start <= '1';
        wait for 30 us;

        report "Simulacion finalizada" severity note;
        wait;
    end process stim;

    monitor : process
        variable t0 : time;
        variable w  : time;
    begin
        loop
            wait until rising_edge(led);
            t0 := now;
            wait until falling_edge(led);
            w := now - t0;
            if w = DOT_TIME then
                report "Punto detectado" severity note;
            elsif w = DASH_TIME then
                report "Raya detectada" severity note;
            else
                report "Ancho de pulso invalido" severity error;
            end if;
        end loop;
    end process monitor;

end architecture sim;
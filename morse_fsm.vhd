library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity morse_fsm is
    generic (
        CLK_FREQ : positive := 50_000_000
    );
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        start : in  std_logic;
        sw    : in  std_logic_vector(2 downto 0);
        led   : out std_logic
    );
end entity morse_fsm;

architecture rtl of morse_fsm is

    constant DOT_T  : natural := CLK_FREQ / 2;
    constant DASH_T : natural := (3 * CLK_FREQ) / 2;

    type state_t is (IDLE, LOAD, PULSE, GAP, DONE);
    signal state, nstate : state_t;

    signal code_w    : std_logic_vector(3 downto 0);
    signal len_w     : unsigned(2 downto 0);
    signal shreg     : std_logic_vector(3 downto 0);
    signal remaining : unsigned(2 downto 0);

    signal cnt   : unsigned(26 downto 0);
    signal limit : unsigned(26 downto 0);
    signal tick  : std_logic;

    signal start_s0, start_s1 : std_logic;

begin

    letter_sel : process (sw)
    begin
        case sw is
            when "000"  => code_w <= "0100"; len_w <= to_unsigned(2, 3);
            when "001"  => code_w <= "1000"; len_w <= to_unsigned(4, 3);
            when "010"  => code_w <= "1010"; len_w <= to_unsigned(4, 3);
            when "011"  => code_w <= "1000"; len_w <= to_unsigned(3, 3);
            when "100"  => code_w <= "0000"; len_w <= to_unsigned(1, 3);
            when "101"  => code_w <= "0010"; len_w <= to_unsigned(4, 3);
            when "110"  => code_w <= "1100"; len_w <= to_unsigned(3, 3);
            when others => code_w <= "0000"; len_w <= to_unsigned(4, 3);
        end case;
    end process letter_sel;

    limit <= to_unsigned(DASH_T - 1, limit'length)
                 when (state = PULSE and shreg(3) = '1')
             else to_unsigned(DOT_T - 1, limit'length);

    tick <= '1' when cnt = limit else '0';

    seq : process (clk, rst)
    begin
        if rst = '0' then
            state     <= IDLE;
            cnt       <= (others => '0');
            shreg     <= (others => '0');
            remaining <= (others => '0');
            start_s0  <= '1';
            start_s1  <= '1';
        elsif rising_edge(clk) then
            start_s0 <= start;
            start_s1 <= start_s0;

            state <= nstate;

            if (state = PULSE or state = GAP) and nstate = state then
                cnt <= cnt + 1;
            else
                cnt <= (others => '0');
            end if;

            case state is
                when LOAD =>
                    shreg     <= code_w;
                    remaining <= len_w;
                when GAP =>
                    if tick = '1' then
                        shreg     <= shreg(2 downto 0) & '0';
                        remaining <= remaining - 1;
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process seq;

    next_state : process (state, start_s1, tick, remaining)
    begin
        nstate <= state;
        case state is
            when IDLE =>
                if start_s1 = '0' then
                    nstate <= LOAD;
                end if;
            when LOAD =>
                nstate <= PULSE;
            when PULSE =>
                if tick = '1' then
                    if remaining = 1 then
                        nstate <= DONE;
                    else
                        nstate <= GAP;
                    end if;
                end if;
            when GAP =>
                if tick = '1' then
                    nstate <= PULSE;
                end if;
            when DONE =>
                if start_s1 = '1' then
                    nstate <= IDLE;
                end if;
        end case;
    end process next_state;

    led <= '1' when state = PULSE else '0';

end architecture rtl;
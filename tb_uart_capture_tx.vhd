library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL;

library STD;
use STD.textio.all;

use work.txt_util.all;
use work.log2.all;


entity tb_uart_capture_tx is
generic (
  baudrate : natural := 115200;
  bit_time : time := 8.68 us;
  SEND_LOG_NAME : string := "send.log";
  stop_mark : std_logic_vector(7 downto 0) -- Stop marker byte
);
port (
  txd : in std_logic;
  stop : out boolean; -- will go to true when a stop marker is found
  framing_errors : out natural;
  total_count : out natural
);
end entity tb_uart_capture_tx;


architecture testbench of tb_uart_capture_tx is

subtype t_byte is std_logic_vector(7 downto 0);

begin

capture_tx: process

   file s_file: TEXT; -- open write_mode is send_logfile;
   variable byte : t_byte;
   variable f_e : natural :=0;
   variable cnt : natural :=0;

   begin
     stop <= false;
     file_open(s_file,SEND_LOG_NAME,WRITE_MODE);
     wait until txd='1'; -- Idle condition
     byte:=(others=>'U');
     while byte/=stop_mark loop -- Wait for End of File marker...
       byte:=(others=>'U');
       wait until txd='0';
       wait for bit_time*1.5; -- Wait until midle of first data bit
       for i in 0 to 7 loop
         byte(i):=txd;
         wait for bit_time;
       end loop;
       cnt:=cnt + 1;
       if txd='0' then
         f_e:=f_e + 1;
         report "Framing error encountered"
         severity warning;
       end if;
       write_charbyte(s_file,byte);
     end loop;
     file_close(s_file);

     stop<=true;
     framing_errors <= f_e;
     total_count <= cnt;
     wait;
   end process;


end architecture testbench;

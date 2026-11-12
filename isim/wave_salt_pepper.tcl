# ISim waveform setup: salt & pepper removal
wave add /tb_salt_pepper_removal/clk
wave add /tb_salt_pepper_removal/rst
wave add /tb_salt_pepper_removal/start
wave add /tb_salt_pepper_removal/dut_state -radix unsigned
wave add /tb_salt_pepper_removal/dut_counter -radix unsigned
wave add /tb_salt_pepper_removal/filtered_pixel -radix hex
wave add /tb_salt_pepper_removal/filtered_valid
wave add /tb_salt_pepper_removal/pixel_addr -radix unsigned
wave add /tb_salt_pepper_removal/done
run all

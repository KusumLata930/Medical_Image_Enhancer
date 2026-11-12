# ISim waveform setup: contrast stretching
wave add /tb_image_enhancer/clk
wave add /tb_image_enhancer/rst
wave add /tb_image_enhancer/start
wave add /tb_image_enhancer/dut_state -radix unsigned
wave add /tb_image_enhancer/dut_counter -radix unsigned
wave add /tb_image_enhancer/dut_min_val -radix unsigned
wave add /tb_image_enhancer/dut_max_val -radix unsigned
wave add /tb_image_enhancer/enhanced_pixel -radix hex
wave add /tb_image_enhancer/enhanced_valid
wave add /tb_image_enhancer/pixel_addr -radix unsigned
wave add /tb_image_enhancer/done
run all

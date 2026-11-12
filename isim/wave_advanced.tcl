# ISim waveform setup: histogram equalisation / threshold
wave add /tb_image_enhancer_advanced/clk
wave add /tb_image_enhancer_advanced/rst
wave add /tb_image_enhancer_advanced/start
wave add /tb_image_enhancer_advanced/mode -radix unsigned
wave add /tb_image_enhancer_advanced/threshold_value -radix unsigned
wave add /tb_image_enhancer_advanced/dut_state -radix unsigned
wave add /tb_image_enhancer_advanced/dut_counter -radix unsigned
wave add /tb_image_enhancer_advanced/dut_cdf_min -radix unsigned
wave add /tb_image_enhancer_advanced/enhanced_pixel -radix hex
wave add /tb_image_enhancer_advanced/enhanced_valid
wave add /tb_image_enhancer_advanced/pixel_addr -radix unsigned
wave add /tb_image_enhancer_advanced/done
run all

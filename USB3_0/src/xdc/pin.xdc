############## NET - IOSTANDARD ##################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
#############SPI Configurate Setting##################
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
############# clock #########################
set_property IOSTANDARD LVCMOS33 [get_ports clk_rtl]
set_property PACKAGE_PIN Y18 [get_ports clk_rtl]
create_clock -period 20.000 [get_ports clk_rtl]
############# reset ##########################
set_property IOSTANDARD LVCMOS33 [get_ports rstn_rtl]
set_property PACKAGE_PIN F20 [get_ports rstn_rtl]
########################### LED Define ###########################
# set_property PACKAGE_PIN F19 [get_ports {led_n_rtl[0]}]
# set_property PACKAGE_PIN E21 [get_ports {led_n_rtl[1]}]
# set_property PACKAGE_PIN D20 [get_ports {led_n_rtl[2]}]
# set_property PACKAGE_PIN C20 [get_ports {led_n_rtl[3]}]

# set_property IOSTANDARD LVCMOS33 [get_ports {led_n_rtl[*]}]
########################### USB3.0 Define ###########################
set_property PACKAGE_PIN D16 [get_ports {usb_led[0]}]
set_property PACKAGE_PIN E16 [get_ports {usb_led[1]}]
set_property PACKAGE_PIN F14 [get_ports {usb_led[2]}]
set_property PACKAGE_PIN E14 [get_ports {usb_gpio[0]}]
set_property PACKAGE_PIN F13 [get_ports {usb_gpio[1]}]
set_property PACKAGE_PIN E13 [get_ports usb_wakeup_n]
set_property PACKAGE_PIN D15 [get_ports usb_rstn]
set_property PACKAGE_PIN D14 [get_ports usb_oe_n]
set_property PACKAGE_PIN B13 [get_ports usb_rd_n]
set_property PACKAGE_PIN C13 [get_ports usb_wr_n]
set_property PACKAGE_PIN A14 [get_ports usb_siwu_n]
set_property PACKAGE_PIN C15 [get_ports usb_txe_n]
set_property PACKAGE_PIN A13 [get_ports usb_rxf_n]
set_property PACKAGE_PIN C18 [get_ports usb_clk]
set_property PACKAGE_PIN A16 [get_ports {usb_be[0]}]
set_property PACKAGE_PIN C14 [get_ports {usb_be[1]}]
set_property PACKAGE_PIN F18 [get_ports {usb_data[0]}]
set_property PACKAGE_PIN E18 [get_ports {usb_data[1]}]
set_property PACKAGE_PIN E19 [get_ports {usb_data[2]}]
set_property PACKAGE_PIN D19 [get_ports {usb_data[3]}]
set_property PACKAGE_PIN D17 [get_ports {usb_data[4]}]
set_property PACKAGE_PIN C17 [get_ports {usb_data[5]}]
set_property PACKAGE_PIN B20 [get_ports {usb_data[6]}]
set_property PACKAGE_PIN A20 [get_ports {usb_data[7]}]
set_property PACKAGE_PIN C19 [get_ports {usb_data[8]}]
set_property PACKAGE_PIN A18 [get_ports {usb_data[9]}]
set_property PACKAGE_PIN A19 [get_ports {usb_data[10]}]
set_property PACKAGE_PIN B17 [get_ports {usb_data[11]}]
set_property PACKAGE_PIN B18 [get_ports {usb_data[12]}]
set_property PACKAGE_PIN B15 [get_ports {usb_data[13]}]
set_property PACKAGE_PIN B16 [get_ports {usb_data[14]}]
set_property PACKAGE_PIN A15 [get_ports {usb_data[15]}]

set_property IOSTANDARD LVCMOS33 [get_ports {usb_led[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {usb_gpio[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports usb_wakeup_n]
set_property IOSTANDARD LVCMOS33 [get_ports usb_rstn]
set_property IOSTANDARD LVCMOS33 [get_ports usb_oe_n]
set_property IOSTANDARD LVCMOS33 [get_ports usb_rd_n]
set_property IOSTANDARD LVCMOS33 [get_ports usb_wr_n]
set_property IOSTANDARD LVCMOS33 [get_ports usb_siwu_n]
set_property IOSTANDARD LVCMOS33 [get_ports usb_txe_n]
set_property IOSTANDARD LVCMOS33 [get_ports usb_rxf_n]
set_property IOSTANDARD LVCMOS33 [get_ports usb_clk]
set_property IOSTANDARD LVCMOS33 [get_ports {usb_be[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {usb_data[*]}]


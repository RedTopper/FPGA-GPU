# Ethernet constraints

# IDELAY on RGMII from PHY chip
set_property IDELAY_VALUE 0 [get_cells {phy_rx_ctl_idelay phy_rxd_idelay_*}]

# Have to specify clocks in design for other constraints to work
create_clock -period 10.000 -name clk [get_ports clk]
create_clock -period 8.000 -name phy_rx_clk [get_ports phy_rx_clk]
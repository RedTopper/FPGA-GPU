
# VDMA false path constraints
# Not checking for match - comment out if not using VDMA
# https://www.xilinx.com/support/answers/71984.html
set_false_path -from [get_cells -hierarchical  -filter "NAME =~*axi_vdma_0*MM2S*LB_BUILT_IN*/*rstbt*/*rst_reg[*]"]
set_false_path -from [get_cells -hierarchical  -filter "NAME =~*axi_vdma_0*MM2S*LB_BUILT_IN*/*rstbt*/*rst_reg_reg"]
set_false_path -to   [get_pins  -hierarchical  -filter "NAME =~*axi_vdma_0*MM2S*LB_BUILT_IN*/*rstbt*/*PRE"]


# AXI stream asynchronous FIFO timing constraints
foreach fifo_inst [get_cells -hier -filter {(ORIG_REF_NAME == axis_async_fifo || REF_NAME == axis_async_fifo)}] {
    puts "Inserting timing constraints for axis_async_fifo instance $fifo_inst"

    # get clock periods
    set read_clk [get_clocks -of_objects [get_pins $fifo_inst/rd_ptr_reg_reg[0]/C]]
    set write_clk [get_clocks -of_objects [get_pins $fifo_inst/wr_ptr_reg_reg[0]/C]]

    set read_clk_period [get_property -min PERIOD $read_clk]
    set write_clk_period [get_property -min PERIOD $write_clk]

    set min_clk_period [expr $read_clk_period < $write_clk_period ? $read_clk_period : $write_clk_period]

    # reset synchronization
    set reset_ffs [get_cells -quiet -hier -regexp ".*/(s|m)_rst_sync\[123\]_reg_reg" -filter "PARENT == $fifo_inst"]

    if {[llength $reset_ffs]} {
        set_property ASYNC_REG TRUE $reset_ffs
        set_false_path -to [get_pins -of_objects $reset_ffs -filter {IS_PRESET || IS_RESET}]
    }

    if {[llength [get_cells -quiet $fifo_inst/s_rst_sync2_reg_reg]]} {
        set_false_path -to [get_pins $fifo_inst/s_rst_sync2_reg_reg/D]
        set_max_delay  -from [get_cells $fifo_inst/s_rst_sync2_reg_reg] -to [get_cells $fifo_inst/s_rst_sync3_reg_reg] $min_clk_period
    }

    if {[llength [get_cells -quiet $fifo_inst/m_rst_sync2_reg_reg]]} {
        set_false_path -to [get_pins $fifo_inst/m_rst_sync2_reg_reg/D]
        set_max_delay  -from [get_cells $fifo_inst/m_rst_sync2_reg_reg] -to [get_cells $fifo_inst/m_rst_sync3_reg_reg] $min_clk_period
    }

    # pointer synchronization
    set_property ASYNC_REG TRUE [get_cells -hier -regexp ".*/(wr|rd)_ptr_gray_sync\[12\]_reg_reg\\\[\\d+\\\]" -filter "PARENT == $fifo_inst"]

    set_max_delay -from [get_cells "$fifo_inst/rd_ptr_reg_reg[*] $fifo_inst/rd_ptr_gray_reg_reg[*]"] -to [get_cells $fifo_inst/rd_ptr_gray_sync1_reg_reg[*]] -datapath_only $read_clk_period
    set_bus_skew  -from [get_cells "$fifo_inst/rd_ptr_reg_reg[*] $fifo_inst/rd_ptr_gray_reg_reg[*]"] -to [get_cells $fifo_inst/rd_ptr_gray_sync1_reg_reg[*]] $write_clk_period
    set_max_delay -from [get_cells -quiet "$fifo_inst/wr_ptr_reg_reg[*] $fifo_inst/wr_ptr_gray_reg_reg[*] $fifo_inst/wr_ptr_sync_gray_reg_reg[*]"] -to [get_cells $fifo_inst/wr_ptr_gray_sync1_reg_reg[*]] -datapath_only $write_clk_period
    set_bus_skew  -from [get_cells -quiet "$fifo_inst/wr_ptr_reg_reg[*] $fifo_inst/wr_ptr_gray_reg_reg[*] $fifo_inst/wr_ptr_sync_gray_reg_reg[*]"] -to [get_cells $fifo_inst/wr_ptr_gray_sync1_reg_reg[*]] $read_clk_period

    # output register (needed for distributed RAM sync write/async read)
    set output_reg_ffs [get_cells -quiet "$fifo_inst/mem_read_data_reg_reg[*]"]

    if {[llength $output_reg_ffs]} {
        set_false_path -from $write_clk -to $output_reg_ffs
    }

    # frame FIFO pointer update synchronization
    set update_ffs [get_cells -quiet -hier -regexp ".*/wr_ptr_update(_ack)?_sync\[123\]_reg_reg" -filter "PARENT == $fifo_inst"]

    if {[llength $update_ffs]} {
        set_property ASYNC_REG TRUE $update_ffs

        set_max_delay -from [get_cells $fifo_inst/wr_ptr_update_reg_reg] -to [get_cells $fifo_inst/wr_ptr_update_sync1_reg_reg] -datapath_only $write_clk_period
        set_max_delay -from [get_cells $fifo_inst/wr_ptr_update_sync3_reg_reg] -to [get_cells $fifo_inst/wr_ptr_update_ack_sync1_reg_reg] -datapath_only $read_clk_period
    }

    # status synchronization
    foreach i {overflow bad_frame good_frame} {
        set status_sync_regs [get_cells -quiet -hier -regexp ".*/${i}_sync\[123\]_reg_reg" -filter "PARENT == $fifo_inst"]

        if {[llength $status_sync_regs]} {
            set_property ASYNC_REG TRUE $status_sync_regs

            set_max_delay -from [get_cells $fifo_inst/${i}_sync1_reg_reg] -to [get_cells $fifo_inst/${i}_sync2_reg_reg] -datapath_only $read_clk_period
        }
    }
}



# RGMII Gigabit Ethernet MAC timing constraints

foreach mac_inst [get_cells -hier -filter {(ORIG_REF_NAME == eth_mac_1g_rgmii || REF_NAME == eth_mac_1g_rgmii)}] {
    puts "Inserting timing constraints for eth_mac_1g_rgmii instance $mac_inst"

    set select_ffs [get_cells -hier -regexp ".*/tx_mii_select_sync_reg\\\[\\d\\\]" -filter "PARENT == $mac_inst"]

    if {[llength $select_ffs]} {
        set_property ASYNC_REG TRUE $select_ffs

        set src_clk [get_clocks -of_objects [get_pins $mac_inst/mii_select_reg_reg/C]]

        set_max_delay -from [get_cells $mac_inst/mii_select_reg_reg] -to [get_cells $mac_inst/tx_mii_select_sync_reg[0]] -datapath_only [get_property -min PERIOD $src_clk]
    }

    set select_ffs [get_cells -hier -regexp ".*/rx_mii_select_sync_reg\\\[\\d\\\]" -filter "PARENT == $mac_inst"]

    if {[llength $select_ffs]} {
        set_property ASYNC_REG TRUE $select_ffs

        set src_clk [get_clocks -of_objects [get_pins $mac_inst/mii_select_reg_reg/C]]

        set_max_delay -from [get_cells $mac_inst/mii_select_reg_reg] -to [get_cells $mac_inst/rx_mii_select_sync_reg[0]] -datapath_only [get_property -min PERIOD $src_clk]
    }

    set prescale_ffs [get_cells -hier -regexp ".*/rx_prescale_sync_reg\\\[\\d\\\]" -filter "PARENT == $mac_inst"]

    if {[llength $prescale_ffs]} {
        set_property ASYNC_REG TRUE $prescale_ffs

        set src_clk [get_clocks -of_objects [get_pins $mac_inst/rx_prescale_reg[2]/C]]

        set_max_delay -from [get_cells $mac_inst/rx_prescale_reg[2]] -to [get_cells $mac_inst/rx_prescale_sync_reg[0]] -datapath_only [get_property -min PERIOD $src_clk]
    }


# Ethernet MAC with FIFO timing constraints

foreach mac_inst [get_cells -hier -filter {(ORIG_REF_NAME == eth_mac_1g_fifo || REF_NAME == eth_mac_1g_fifo || \
            ORIG_REF_NAME == eth_mac_10g_fifo || REF_NAME == eth_mac_10g_fifo || \
            ORIG_REF_NAME == eth_mac_1g_gmii_fifo || REF_NAME == eth_mac_1g_gmii_fifo || \
            ORIG_REF_NAME == eth_mac_1g_rgmii_fifo || REF_NAME == eth_mac_1g_rgmii_fifo || \
            ORIG_REF_NAME == eth_mac_mii_fifo || REF_NAME == eth_mac_mii_fifo)}] {
    puts "Inserting timing constraints for ethernet MAC with FIFO instance $mac_inst"

    set sync_ffs [get_cells -hier -regexp ".*/rx_sync_reg_\[1234\]_reg\\\[\\d+\\\]" -filter "PARENT == $mac_inst"]

    if {[llength $sync_ffs]} {
        set_property ASYNC_REG TRUE $sync_ffs

        set src_clk [get_clocks -of_objects [get_pins $mac_inst/rx_sync_reg_1_reg[*]/C]]

        set_max_delay -from [get_cells $mac_inst/rx_sync_reg_1_reg[*]] -to [get_cells $mac_inst/rx_sync_reg_2_reg[*]] -datapath_only [get_property -min PERIOD $src_clk]
    }

    set sync_ffs [get_cells -hier -regexp ".*/tx_sync_reg_\[1234\]_reg\\\[\\d+\\\]" -filter "PARENT == $mac_inst"]



# RGMII PHY IF timing constraints

foreach if_inst [get_cells -hier -filter {(ORIG_REF_NAME == rgmii_phy_if || REF_NAME == rgmii_phy_if)}] {
    puts "Inserting timing constraints for rgmii_phy_if instance $if_inst"

    # reset synchronization
    set reset_ffs [get_cells -hier -regexp ".*/(rx|tx)_rst_reg_reg\\\[\\d\\\]" -filter "PARENT == $if_inst"]

    set_property ASYNC_REG TRUE $reset_ffs
    set_false_path -to [get_pins -of_objects $reset_ffs -filter {IS_PRESET || IS_RESET}]

    # clock output
    set_property ASYNC_REG TRUE [get_cells $if_inst/clk_oddr_inst/oddr[0].oddr_inst]

    set src_clk [get_clocks -of_objects [get_pins $if_inst/rgmii_tx_clk_1_reg/C]]

    set_max_delay -from [get_cells $if_inst/rgmii_tx_clk_1_reg] -to [get_cells $if_inst/clk_oddr_inst/oddr[0].oddr_inst] -datapath_only [expr [get_property -min PERIOD $src_clk]/4]
    set_max_delay -from [get_cells $if_inst/rgmii_tx_clk_2_reg] -to [get_cells $if_inst/clk_oddr_inst/oddr[0].oddr_inst] -datapath_only [expr [get_property -min PERIOD $src_clk]/4]
}



foreach inst [get_cells -hier -filter {(ORIG_REF_NAME == sync_reset || REF_NAME == sync_reset)}] {
    puts "Inserting timing constraints for sync_reset instance $inst"

    # reset synchronization
    set reset_ffs [get_cells -quiet -hier -regexp ".*/sync_reg_reg\\\[\\d+\\\]" -filter "PARENT == $inst"]

    set_property ASYNC_REG TRUE $reset_ffs
    set_false_path -to [get_pins -of_objects $reset_ffs -filter {IS_PRESET || IS_RESET}]
}
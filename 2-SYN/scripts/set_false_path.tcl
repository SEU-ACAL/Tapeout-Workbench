###########################################################################
# Asynchronous reset inputs are handled by ResetCatchAndSync in RTL.  Do
# not analyze them as clock-synchronous data paths.
###########################################################################

set reset_ports [get_ports {reset jtag_reset}]
set_false_path -from $reset_ports

# The non-coherent Serial-TL configuration has no TL-E (GrantAck) traffic.
# Channel 0 is still structurally present in the fixed five-channel PHY, but
# its enqueue valid is constant zero.  Exclude only the resulting dead FIFO
# state-check endpoints from timing; keep all live Serial-TL channels timed.
set serial_tl_dead_e_endpoints [get_pins -hierarchical {
    system/serial_tl_domain/phy/out_phits_out_async_io_enq_q/enq_ptr_value_reg[0]/synch_enable
    system/serial_tl_domain/phy/out_phits_out_async_io_enq_q/enq_ptr_value_reg[1]/synch_enable
    system/serial_tl_domain/phy/out_phits_out_async_io_enq_q/enq_ptr_value_reg[2]/synch_enable
    system/serial_tl_domain/phy/out_phits_out_async_io_enq_q/maybe_full_reg/next_state
}]
if {[sizeof_collection $serial_tl_dead_e_endpoints] > 0} {
    set_false_path -to $serial_tl_dead_e_endpoints
}

###########################################################################
# Asynchronous reset inputs are handled by ResetCatchAndSync in RTL.  Do
# not analyze them as clock-synchronous data paths.
###########################################################################

set reset_ports [get_ports {reset jtag_reset}]
set_false_path -from $reset_ports

# The channel-0 FIFO resides on SerialTL's inner clock, which is driven by
# auto_clock_in_clock (the SoC clock), not serial_tl_0_clock_in.  The inferred
# sequential model exposes these internal state pins as timing endpoints, so
# give them an explicit one-cycle max-delay requirement rather than masking
# them as false paths.
set serial_tl_inner_fifo_state_pins [get_pins -hierarchical {
    system/serial_tl_domain/phy/out_phits_out_async_io_enq_q/enq_ptr_value_reg[0]/synch_enable
    system/serial_tl_domain/phy/out_phits_out_async_io_enq_q/enq_ptr_value_reg[1]/synch_enable
    system/serial_tl_domain/phy/out_phits_out_async_io_enq_q/enq_ptr_value_reg[2]/synch_enable
    system/serial_tl_domain/phy/out_phits_out_async_io_enq_q/maybe_full_reg/next_state
}]
if {[sizeof_collection $serial_tl_inner_fifo_state_pins] > 0} {
    set_max_delay $PAD_cpu_clock_period \
        -from [get_clocks clock] \
        -to $serial_tl_inner_fifo_state_pins
}

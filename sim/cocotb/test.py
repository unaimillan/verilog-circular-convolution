import time
import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

if not cocotb.simulator.is_running():
    raise RuntimeError("Running Cocotb testbench without the simulator")

DATA_LEN   = int(cocotb.top.XLEN.value)
DATA_WIDTH = int(cocotb.top.WIDTH.value)


@cocotb.test()
async def my_first_test(dut):
    """Try accessing the design."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start()) 

    dut._log.info("Initialize and reset model")

    dut.rst.value = 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    dut._log.info(f'DATA LEN & WIDTH: {DATA_LEN}, {DATA_WIDTH}')

    for _ in range(1_000):
        await RisingEdge(dut.clk)
        # dut._log.info("my_signal_1 is %s", dut.x.value)
        # sio.send(dut.x.value.binstr)

    assert dut.rst.value[0] == 0, "my reset value is 0"

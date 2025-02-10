import time
import cocotb
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray, Range
import numpy as np


if not cocotb.simulator.is_running():
    raise RuntimeError("Running Cocotb testbench without the simulator")

XLEN   = int(cocotb.top.XLEN.value)
DATA_WIDTH = int(cocotb.top.WIDTH.value)

# dump_vars?
# reset
# init
# jork {
# driver - drive - input up_a, up_b, down_ready
# monitor - collect data from inputs & outputs into queues or mailboxes
# scoreboard - recieve data from queues or mailboxes and verify it against golden model
# } join


async def drive_input(dut: SimHandleBase, ):
    pass


async def monitor_valid(clk: SimHandleBase, valid: SimHandleBase, data: SimHandleBase, queue: Queue[LogicArray]):
    while True:
        await RisingEdge(clk)
        if valid.value != "1":
            await RisingEdge(valid)
            continue
        queue.put_nowait(data.value)


async def scoreboard(queue_in: Queue[LogicArray], queue_out: Queue[LogicArray]):
    pass


async def reset(clk: SimHandleBase, rst: SimHandleBase):
    rst.value = 1
    for _ in range(3):
        await RisingEdge(clk)
    rst.value = 0
    await RisingEdge(clk)


@cocotb.test()
async def my_first_test(dut):
    dut._log.info("Initialize and reset model")

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start()) 
    await reset()

    in_queue = Queue()
    out_queue = Queue()

    drive_in = cocotb.start_soon(drive_input(dut.clk, dut.in_valid, dut.in_data))

    monitor_in = cocotb.start_soon(monitor_valid(dut.clk, dut.in_valid, dut.in_data, in_queue))
    monitor_out = cocotb.start_soon(monitor_valid(dut.clk, dut.out_valid, dut.out_data, out_queue))

    scoreboard = cocotb.start_soon(scoreboard())

    dut._log.info(f'DATA LEN & WIDTH: {XLEN}, {DATA_WIDTH}')

    kernel = np.concat([np.zeros((DATA_WIDTH//4, )), np.ones((DATA_WIDTH//2,)), np.zeros((DATA_WIDTH//4,))])
    # kernel = np.random.normal(scale=1, size=DATA_WIDTH)

    for _ in range(1_000):
        await RisingEdge(dut.clk)
        # dut._log.info("my_signal_1 is %s", dut.x.value)
        # sio.send(dut.x.value.binstr)

    assert dut.rst.value[0] == 0, "my reset value is 0"

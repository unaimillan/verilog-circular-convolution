import itertools
import json
from pathlib import Path
from typing import Generator
import cocotb
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.types import LogicArray, Range
from cocotb.binary import BinaryValue
import fxpmath
import numpy as np


if not cocotb.simulator.is_running():
    raise RuntimeError("Running Cocotb testbench without the simulator")

XLEN   = int(cocotb.top.XLEN.value)
WINDOW_SIZE = int(cocotb.top.WIDTH.value)
CHECKS_N = 5
ND_KERNEL = np.asarray([0.01]*(WINDOW_SIZE//4) + [0.10]*(WINDOW_SIZE//2) + [0.01]*(WINDOW_SIZE//4))
# ND_KERNEL = np.concat([np.zeros((WINDOW_SIZE//4, )), np.ones((WINDOW_SIZE//2,)), np.zeros((WINDOW_SIZE//4,))])
# ND_KERNEL = np.random.normal(scale=1, size=WINDOW_SIZE)

# dump_vars?
# reset
# init
# jork {
# driver - drive - input up_a, up_b, down_ready
# monitor - collect data from inputs & outputs into queues or mailboxes
# scoreboard - recieve data from queues or mailboxes and verify it against golden model
# } join


def convert_float_to_logic(array: np.ndarray) -> BinaryValue:
    assert XLEN == 16
    fxparr = fxpmath.Fxp(array, signed=True, n_word=16, n_frac=12)
    return BinaryValue("".join(fxparr.bin()))


def convert_logic_to_float(array: BinaryValue) -> np.ndarray:
    assert len(array.binstr) % XLEN == 0, f'binary string array size {len(array.binstr)} should be multiple of XLEN'
    return np.asarray([ 
        fxpmath.Fxp('b'+''.join(binstr), signed=True, n_word=16, n_frac=12) for binstr in itertools.batched(array.binstr, XLEN)
    ])


def generate_sins() -> Generator[np.ndarray[np.float64]]:
    x_start = 0
    x_step = 50
    while True:
        x_end = x_start + x_step
        x = np.linspace(x_start, x_end, WINDOW_SIZE)
        true_y = np.sin(x)
        y_range = np.max(true_y) - np.min(true_y)
        y = true_y + np.random.normal(scale=y_range/10, size=WINDOW_SIZE) + np.sin(x*1.33)
        
        yield y
        x_start += x_step


def generate_random() -> Generator[np.ndarray[np.float64]]:
    while True:
        y = np.random.normal(scale=1, size=WINDOW_SIZE)
        yield y


async def drive_valid_data(clk: SimHandleBase, valid: SimHandleBase, data: SimHandleBase):
    generate_func = generate_sins
    fix_delay = WINDOW_SIZE + 10

    for i, ndsample in enumerate(generate_func()):

        valid.value = 1
        data.value = convert_float_to_logic(ndsample)

        await RisingEdge(clk)
        # wait for up_ready if any

        valid.value = 0
        
        # if i % 100 == 0:
        data._log.info(f"{i} idx input sample send")

        rand_delay = cocotb.random.randint(5, 10)
        await ClockCycles(clk, fix_delay + rand_delay)


async def monitor_valid(clk: SimHandleBase, valid: SimHandleBase, data: SimHandleBase, queue: Queue[BinaryValue]):
    while True:
        await RisingEdge(clk)
        if valid.value != 1:
            await RisingEdge(valid)
            continue
        queue.put_nowait(data.value)


def model_check(array: np.ndarray) -> np.ndarray:
    return np.real(np.fft.ifft(np.fft.fft(array)*np.fft.fft(ND_KERNEL)))


async def scoreboard(in_queue: Queue[BinaryValue], out_queue: Queue[BinaryValue]):
    data_log = []
    for check_i in range(CHECKS_N):
        in_data = await in_queue.get()
        out_data = await out_queue.get()

        ndin_data = convert_logic_to_float(in_data)
        ndout_data = convert_logic_to_float(out_data)
        expected_data = model_check(ndin_data)
        exp_size = 10 ** -3

        equal = np.all(np.abs(ndout_data - expected_data) < exp_size)
        if not equal:
            print(ndin_data)
            print(f'Expected:\n{expected_data}\nReceived:\n{ndout_data}')
            # assert equal

        cocotb.log.info(f'{check_i} check complete')
        data_log.append([ndin_data.tolist(), ndout_data.tolist(), expected_data.tolist()])
    (Path('.') / 'data.log').write_text(json.dumps(data_log))


async def reset(clk: SimHandleBase, rst: SimHandleBase):
    rst.value = 1
    for _ in range(3):
        await RisingEdge(clk)
    rst.value = 0
    await RisingEdge(clk)


@cocotb.test()
async def my_first_test(dut):
    dut._log.info("Initialize and reset model")
    dut._log.info(f'DATA LEN & WIDTH: {XLEN}, {WINDOW_SIZE}')

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start()) 
    await reset(dut.clk, dut.rst)

    dut.weights.value = convert_float_to_logic(ND_KERNEL)
    await RisingEdge(dut.clk)

    in_queue = Queue()
    out_queue = Queue()

    drive_in = cocotb.start_soon(drive_valid_data(dut.clk, dut.in_valid, dut.in_data))

    monitor_in = cocotb.start_soon(monitor_valid(dut.clk, dut.in_valid, dut.in_data, in_queue))
    monitor_out = cocotb.start_soon(monitor_valid(dut.clk, dut.out_valid, dut.out_data, out_queue))

    await scoreboard(in_queue, out_queue)

    await ClockCycles(dut.clk, 30)

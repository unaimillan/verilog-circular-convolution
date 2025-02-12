import itertools
import cocotb
from cocotb.triggers import Timer
from cocotb.binary import BinaryValue
import fxpmath
import numpy as np


if not cocotb.simulator.is_running():
    raise RuntimeError("Running Cocotb testbench without the simulator")

QLEN = int(cocotb.top.QLEN.value)

@cocotb.test()
async def my_first_test(dut):
    dut._log.info("Initialize and reset model")
    dut._log.info(f'DATA LEN & WIDTH: {QLEN}')

    TIME_STEP = 5
    await Timer(TIME_STEP)

    q = lambda x: fxpmath.Fxp(x, True, 16, 12)
    bn = BinaryValue

    assert QLEN == 16

    arg_list = [0, 0.001, 0.03, 0.12, 1]
    arg_list = arg_list + (-np.asarray(arg_list)).tolist()

    correct_cnt = 0
    cnt = 0
    for a, b in itertools.product(arg_list, arg_list):
        fxp_a = q(a)
        fxp_b = q(b)
        exp_res = q('b'+(fxp_a * fxp_b).bin()[4:4+16])
        dut.a.value = bn(fxp_a.bin())
        dut.b.value = bn(fxp_b.bin())
        dut.expected_res.value = bn(exp_res.bin())

        await Timer(TIME_STEP)

        res = q('b' + dut.res.value.binstr)
        correct = bool(exp_res == res)
        print(f'{a:6} {b:6} {res.astype(float): 8.6f} {exp_res.astype(float): 8.6f}', 
              dut.a.value, dut.b.value, res.bin(), exp_res.bin(), '*'*(not correct)
        )
        correct_cnt += correct
        cnt += 1

        await Timer(TIME_STEP)
    
    assert correct_cnt == cnt

import os
from pathlib import Path
from cocotb.runner import get_runner

def test_with_cocotb():

    sim = os.getenv("SIM", "icarus")
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")

    proj_path = Path(__file__).resolve().parent / '../../..'
    print(f'Project path: {proj_path.absolute()}')

    verilog_sources = [
        # *(proj_path / 'src').rglob('*.svh'),
        *(proj_path / 'rtl').rglob('*.sv'),
        # *(proj_path / 'src').glob('*.v'),
        # *(proj_path / 'peripherals').glob('*.sv')
    ]
    vhdl_sources = []

    verilog_includes = [
        # *(proj_path / 'src').rglob('*.svh'),
    ]

    if hdl_toplevel_lang == "verilog":
        verilog_sources.append(proj_path / "sim/cocotb/fxp_tb/dut.sv")
    else:
        vhdl_sources.append(proj_path / "top.vhdl")

    print('Discovered source files:', *map(lambda p: p.name, verilog_sources))

    runner = get_runner(sim)
    runner.build(
        verilog_sources=verilog_sources,
        vhdl_sources=vhdl_sources,
        includes=verilog_includes,
        hdl_toplevel="dut",
        always=True,
    )

    runner.test(hdl_toplevel="dut", test_module="test", waves=True, gui=True)


if __name__ == "__main__":
    test_with_cocotb()

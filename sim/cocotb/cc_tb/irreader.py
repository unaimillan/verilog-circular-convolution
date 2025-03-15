import scipy.io.wavfile as wv
import os 
import numpy as np
from pathlib import Path

SAMPLES_PATH = Path(os.path.dirname(os.path.realpath(__file__))) / "ir_samples"

def _read_ir(path: str) -> np.ndarray:
     sample_rate, data = wv.read(path)

     data = data.astype(np.float32) / np.iinfo(data.dtype).max

     assert np.max(np.abs(data)) < 1 

     return data

def read_ir(shift: int = 0) -> np.ndarray:
     directory = SAMPLES_PATH
     files = [f for f in directory.iterdir() if f.is_file() and f.name.endswith('.wav')]

     return _read_ir(files[shift])

import numpy as np
from numpy.fft import fft, ifft


def cc_direct(signal: np.ndarray, kernel:np.ndarray):
    result = np.zeros(len(signal))
    for k in range(len(signal)):
        for p in range(len(signal)):
            result[k] = result[k] + (signal[p] * kernel[k-p])
    return result


def cc_fft(signal: np.ndarray, ker: np.ndarray):
    return np.real(ifft(fft(signal)*fft(ker)))

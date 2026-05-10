This RTL set implements ADC capture, 1024-point FFT streaming, spectrum feature extraction, and a simple AM/FM/CW classifier.

Replace xfft_1024_stub.v with your Xilinx FFT IP (same module name) or update fft_wrapper.v to match your IP name.

Classification rule:
- peak_count <= 1: CW
- peak_count <= 3: AM
- otherwise: FM

Tune the threshold in feature_extract.v by changing (max_mag >> 2).

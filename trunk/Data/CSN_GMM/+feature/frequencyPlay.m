%% playing with FFT
N = 44;
t = [0:(N-1)]' / N
f = sin(2*pi*t)


F = fft(f)

Fnorm = abs(F) / (N/2) % this gets magnitudes for both positive and negative frequencies

p = Fnorm(1:N/2).^2 % power spectrum of only the positive frequencies

freq = [0:N/2-1]/T

%%
%From:
%Computing Fourier Series and Power Spectrum with MATLAB
%By Brian D. Storey


N = 100;
% number of points
T = 3.4;
% define time of interval, 3.4 seconds
t = [0:N-1]/N;
% define time
t = t*T;
% define time in seconds
f = sin(2*pi*10*t);
%define function, 10 Hz sine wave
p = abs(fft(f))/(N/2);
% absolute value of the fft
p = p(1:N/2).^2
% take the power of positve freq. half

freq = [0:N/2-1]/T;
% find the corresponding frequency in Hz
figure()
semilogy(freq,p);
% plot on semilog scale
axis([0 20 0 1]);
% zoom in

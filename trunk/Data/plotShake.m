%D = load('9_desk.acsn');
%D = load('5desktop01.acsn');
%D = load('B/sevendesktwo.acsn'); % not very impressive
%D = load('G/walking_8_mnf.acsn'); % looks nice 
%D = load('morning/morning_2.acsn');
L = size(D,1);

x = D(:,1);
y = D(:,2);
z = D(:,3);
t = D(:,4);

Fs = 80; %Hz
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(z,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);

% Plot single-sided amplitude spectrum.
plot(f,2*abs(Y(1:NFFT/2+1))) 
axis([0 2.5 0 0.025])
title('Single-Sided Amplitude Spectrum, 9 desk y')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')
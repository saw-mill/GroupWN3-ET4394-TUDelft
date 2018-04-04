%% 802.11 Dynamic Rate Control Simulation- Group WN3 Saumil & Niket | ET4394 TU Delft

% Dynamic rate control algorithm for IEEE 802.11 WLAN which is built upon
% the rate control algorithm provided by Matlab in their WLAN toolbox
% TransmitRateControlExample.m

%% Introduction
% The IEEE(R) 802.11(TM) standard supports dynamic rate control by
% adjusting the MCS value of each transmitted packet based on the
% underlying radio propagation channel. Maximizing link throughput, in a
% propagation channel that is time varying due to multipath fading or
% movement of the surrounding objects, requires dynamic variation of MCS.
% The IEEE 802.11 standard does not define any standardized rate control
% algorithm (RCA) for dynamically varying the modulation rate. The
% implementation of RCA is left open to the WLAN device manufacturers. This
% example uses a closed-loop rate control scheme. A recommended MCS for
% transmitting a packet is calculated at the receiver and is available at
% the transmitter without any feedback latency. In a real system this
% information would be conveyed through a control frame exchange. The MCS
% is adjusted for each subsequent packet in response to an evolving channel
% condition with noise power varying over time.
%
% In this example, an IEEE 802.11ac(TM) [ <#10 1> ] waveform consisting of
% a single VHT format packet is generated using
% <matlab:doc('wlanWaveformGenerator') wlanWaveformGenerator>. The waveform
% is passed through a TGac channel and noise is added. The packet is
% synchronized and decoded to recover the PSDU. The SNR is estimated and
% compared against thresholds to determine which MCS is suitable for
% transmission of the next packet. This figure shows the processing for
% each packet.
%
% <<RCAschematic.png>>
%
%% Waveform Configuration
% An IEEE 802.11ac VHT transmission is simulated in this example. The VHT
% waveform properties are specified in a <matlab:doc('wlanVHTConfig')
% wlanVHTConfig> configuration object. In this example the object is
% initially configured for a 40 MHz channel bandwidth, single transmit
% antenna and QPSK rate-1/2 (MCS 1). The MCS for the subsequent packets
% is changed by the algorithm throughout the simulation.
cfgVHT = wlanVHTConfig;
cfgVHT.ChannelBandwidth = 'CBW40'; % 40 MHz channel bandwidth
cfgVHT.MCS = 1;                    % QPSK rate-1/2
cfgVHT.APEPLength = 4096;          % APEP length in bytes

% Set random stream for repeatability of results
s = rng(21);

MCS = [0,1,2,3,4,5,6,7,8,9];
% Threshold vectors to be choosen depending on the Channel bandwidth. NOTE-
% 20MHz CBW not supported in this Algorithm
switch cfgVHT.ChannelBandwidth
    case 'CBW40'
        LTs=[5,8,12,14,18,21,23,28,32,36];
        HTs=[7,11,13,17,20,22,27,31,33,38];
    case 'CBW80'
        LTs=[8,11,15,17,21,24,26,31,35,37];
        HTs=[10,14,16,20,23,25,30,34,36,39];
    case 'CBW160'
        LTs=[11,14,18,20,24,27,29,34,38,40];
        HTs=[13,17,19,23,26,28,33,37,39,42];
    otherwise
        warning('Channel Width not supported in this Algorithm')
end

% Mapping MCS vector to the Threshold vectors
LTMap = containers.Map(MCS,LTs);
HTMap= containers.Map(MCS,HTs);

%% Channel Configuration
% In this example a TGac N-LOS channel model is used with delay profile
% Model-D. For Model-D when the distance between the transmitter and
% receiver is greater than or equal to 10 meters, the model is NLOS. This
% is described further in <matlab:doc('wlanTGacChannel') wlanTGacChannel>.

tgacChannel = wlanTGacChannel;
tgacChannel.DelayProfile = 'Model-D';
tgacChannel.ChannelBandwidth = cfgVHT.ChannelBandwidth;
tgacChannel.NumTransmitAntennas = 1;
tgacChannel.NumReceiveAntennas = 1;
tgacChannel.TransmitReceiveDistance = 20; % Distance in meters for NLOS
tgacChannel.RandomStream = 'mt19937ar with seed';
tgacChannel.Seed = 10;

% Set the sampling rate for the channel
sr = wlanSampleRate(cfgVHT);
tgacChannel.SampleRate = sr;

%% Rate Control Algorithm Parameters
% Typically RCAs use channel quality or link performance metrics, such as
% SNR or packet error rate, for rate selection. The RCA presented in this
% example estimates the SNR of a received packet. On reception, the
% estimated SNR is compared against a predefined threshold. If the SNR
% exceeds the predefined threshold then a new MCS is selected for
% transmitting the next packet. The |rcaAttack| and |rcaRelease| controls
% smooth rate changes to avoid changing rates prematurely. The SNR must
% exceed the |threshold| + |rcaAttack| value to increase the MCS and must
% be under the |threshold| - |rcaRelease| value to decrease the MCS. In
% this simulation |rcaAttack| and |rcaRelease| are set to conservatively
% increase the MCS and aggressively reduce it. For the |threshold| values
% selected for the scenario simulated in this example, a small number of
% packet errors are expected. These settings may not be suitable for other
% scenarios.

snrInd = cfgVHT.MCS; % Store the start MCS value

%% Simulation Parameters
% In this simulation |numPackets| packets are transmitted through a TGac
% channel, separated by a fixed idle time. The channel state is maintained
% throughout the simulation, therefore the channel evolves slowly over
% time. This evolution slowly changes the resulting SNR measured at the
% receiver. Since the TGac channel changes very slowly over time, here an
% SNR variation at the receiver visible over a short simulation can be
% forced using the |walkSNR| parameter to modify the noise power:
%
% # Setting |walkSNR| to true generates a varying SNR by randomly setting
% the noise power per packet during transmission. The SNR walks between
% 14-33 dB (using the |amplitude| and |meanSNR| variables).
% # Setting |walkSNR| to false fixes the noise power applied to the
% received waveform, so that channel variations are the main source of SNR
% changes at the receiver.

numPackets = 100; % Number of packets transmitted during the simulation
walkSNR = true;

% Select SNR for the simulation
if walkSNR
    meanSNR = 22;   % Mean SNR
    amplitude = 14; % Variation in SNR around the average mean SNR value
    % Generate varying SNR values for each transmitted packet
    baseSNR = sin(linspace(1,10,numPackets))*amplitude+meanSNR;
    snrWalk = baseSNR(1); % Set the initial SNR value
    % The maxJump controls the maximum SNR difference between one
    % packet and the next
    maxJump = 0.5;
else
    % Fixed mean SNR value for each transmitted packet. All the variability
    % in SNR comes from a time varying radio channel
    snrWalk = 22; %#ok<UNRCH>
end

% To plot the equalized constellation for each spatial stream set
% displayConstellation to true
displayConstellation = false;
if displayConstellation
    ConstellationDiagram = comm.ConstellationDiagram; %#ok<UNRCH>
    ConstellationDiagram.ShowGrid = true;
    ConstellationDiagram.Name = 'Equalized data symbols';
end

% Define simulation variables
snrMeasured = zeros(1,numPackets);
MCS = zeros(1,numPackets);
ber = zeros(1,numPackets);
packetLength = zeros(1,numPackets);
%% Processing Chain
% The following processing steps occur for each packet:
%
% # A PSDU is created and encoded to create a single packet waveform.
% # A fixed idle time is added between successive packets.
% # The waveform is passed through an evolving TGac channel.
% # AWGN is added to the transmitted waveform to create the desired average
% SNR per subcarrier.
% # This local function |processPacket| passes the transmitted waveform
% through the TGac channel, performs receiver processing, and SNR
% estimation.
% # The L-LTF is extracted from the synchronized received waveform. The
% L-LTF is OFDM demodulated and noise estimation is performed.
% # The VHT-LTF is extracted from the received waveform. The
% VHT-LTF is OFDM demodulated and channel estimation is performed.
% # The SNR is estimated using the VHT-LTF field and the noise estimates
% are computed using L-LTF.
% # The estimated SNR is compared against the threshold, the comparison is
% used to adjust the MCS for the next packet.
% # The VHT Data field is extracted from the synchronized received
% waveform. The PSDU is recovered using the extracted field.

%%
% For simplicity, this example assumes:
%
% # Fixed bandwidth and antenna configuration for each transmitted packet.
% # There is no explicit feedback packet to inform the transmitter about
% the suggested MCS setting for the next packet. The example assumes that
% this information is known to the transmitter before transmitting the
% subsequent packet.
% # Fixed idle time of 0.5 milliseconds between packets.

%  randArray=5 + 33.*rand(100,1);   % Setting up Array to be used in Dynamic Conditions
for numPkt = 1:numPackets
    if walkSNR
        % Generate SNR value per packet using random walk algorithm biased
        % towards the mean SNR
        snrWalk = 0.9*snrWalk+0.1*baseSNR(numPkt)+rand(1)*maxJump*2-maxJump;
        % snrWalk = randArray(numPkt);    % For Dynamic conditions
    end
    
    % Generate a single packet waveform
    txPSDU = randi([0,1],8*cfgVHT.PSDULength,1,'int8');
    txWave = wlanWaveformGenerator(txPSDU,cfgVHT,'IdleTime',5e-4);
    
    % Receive processing, including SNR estimation
    y = processPacket(txWave,snrWalk,tgacChannel,cfgVHT);
    
    % Plot equalized symbols of data carrying subcarriers
    if displayConstellation && ~isempty(y.EstimatedSNR)
        release(ConstellationDiagram);
        ConstellationDiagram.ReferenceConstellation = helperReferenceSymbols(cfgVHT);
        ConstellationDiagram.Title = ['Packet ' int2str(numPkt)];
        ConstellationDiagram(y.EqDataSym(:));
        drawnow
    end
    
    % Store estimated SNR value for each packet
    if isempty(y.EstimatedSNR)
        snrMeasured(1,numPkt) = NaN;
    else
        snrMeasured(1,numPkt) = y.EstimatedSNR;
    end
    
    % Determine the length of the packet in seconds including idle time
    packetLength(numPkt) = y.RxWaveformLength/sr;
    
    % Calculate packet error rate (PER)
    if isempty(y.RxPSDU)
        % Set the PER of an undetected packet to NaN
        ber(numPkt) = NaN;
    else
        
        [~,ber(numPkt)] = biterr(y.RxPSDU,txPSDU);
        
    end
    if(~isempty(y.EstimatedSNR))
        ReceivedSNR= y.EstimatedSNR;
    else
        ReceivedSNR=0;
    end
    
    % Computing Upper and Lower MCS bounds for the Reveived SNR 
    for i = 9 : -1 : 0
        if ReceivedSNR >= cell2mat(values(LTMap,{i}))
            break;
        end
    end
    
    MCSLowerBound = i;
    
    for i = 0 : 1 : 9
        if ReceivedSNR <= cell2mat(values(HTMap, {i}))
            break;
        end
    end
    
    MCSUpperBound = i;
    
    MCS(numPkt) = cfgVHT.MCS; % Storing the current MCS value
    
    if (ber(numPkt) > 0) % If Packet has a finite Bit Error Rate
        
        %Check if current MCS is in the vicinity of the MCS bounds
        if((((MCSLowerBound-MCS(numPkt))<=1) || ((MCS(numPkt)-MCSUpperBound)<=1)) && (~(MCS(numPkt)==0 || MCS(numPkt)==9)))
            
            % Creating a Probe packet with MCS-1
            cfgVHT.MCS=MCS(numPkt) - 1;
            %Transmitting the Probe packet
            lowertxPSDU = randi([0,1],8*cfgVHT.PSDULength,1,'int8');
            lowertxWave = wlanWaveformGenerator(lowertxPSDU,cfgVHT,'IdleTime',5e-4);
            %Receiving and decoding the probe packet
            z = processPacket(lowertxWave,snrWalk,tgacChannel,cfgVHT);
            %Condition to check empty RxPSDU
            if(isempty(z.RxPSDU))
                ber_lower_mcs = ber(numPkt)+1;
            else
                ber_lower_mcs=biterr(z.RxPSDU,lowertxPSDU);
            end
            
            % Creating a Probe packet with MCS+1
            cfgVHT.MCS=MCS(numPkt) + 1;
            %Transmitting the Probe packet
            highertxPSDU = randi([0,1],8*cfgVHT.PSDULength,1,'int8');
            highertxWave = wlanWaveformGenerator(highertxPSDU,cfgVHT,'IdleTime',5e-4);
            %Receiving and decoding the probe packet
            w = processPacket(highertxWave,snrWalk,tgacChannel,cfgVHT);
            %Condition to check empty RxPSDU
            if(isempty(w.RxPSDU))
                ber_higher_mcs = ber(numPkt)+1;
            else
                ber_higher_mcs=biterr(w.RxPSDU,highertxPSDU);
            end
            
            %If BER of either of the probe packets is lower than BER of current received
            %packet
            if(ber_lower_mcs < ber(numPkt) || (ber_higher_mcs < ber(numPkt)))
                if(ber(numPkt)-ber_lower_mcs) > (ber(numPkt)-ber_higher_mcs)
                    HTs((MCS(numPkt)-1)+1)=ReceivedSNR;
                    LTs(MCS(numPkt)+1)=ReceivedSNR+0.1;
                elseif(ber(numPkt)-ber_lower_mcs) < (ber(numPkt)-ber_higher_mcs)
                    LTs(MCS(numPkt)+1+1)=ReceivedSNR;
                    HTs(MCS(numPkt)+1)=ReceivedSNR-0.1;
                end
            end
        end
    end
    
    % Modifying the new MCS based on the MCS Bound
    if (MCS(numPkt) > MCSUpperBound)
        if(~snrInd==0)
            snrInd=snrInd-1;
        end
        cfgVHT.MCS = snrInd;
    elseif ((MCSLowerBound - MCS(numPkt)) > 1)
        if(~(snrInd==9))
            snrInd=snrInd+1;
        end
        cfgVHT.MCS = snrInd;
    end
end
%% Display and Plot Simulation Results
% This example plots the variation of MCS, SNR, BER, and data throughput
% over the duration of the simulation.
%
% # The MCS used to transmit each packet is plotted. When compared to the
% estimated SNR, you can see the MCS selection is dependent on the
% estimated SNR.
% # The bit error rate per packet depends on the channel conditions, SNR,
% and MCS used for transmission.
% # The throughput is maximized by varying the MCS according to the channel
% conditions. The throughput is calculated using a sliding window of three
% packets. For each point plotted, the throughput is the number of data
% bits, successfully recovered over the duration of three packets. The
% length of the sliding window can be increased to further smooth the
% throughput. You can see drops in the throughput either when the MCS
% decreases or when a packet error occurs.

% Display and plot simulation results
disp(['Overall data rate: ' num2str(8*cfgVHT.APEPLength*(numPackets-numel(find(ber)))/sum(packetLength)/1e6) ' Mbps']);
disp(['Overall packet error rate: ' num2str(numel(find(ber))/numPackets)]);

plotResults(ber,packetLength,snrMeasured,MCS,cfgVHT);

% Restore default stream
rng(s);

%% Conclusion and Further Exploration
% This example uses a closed-loop rate control scheme where knowledge of
% the MCS used for subsequent packet transmission is assumed to be
% available to the transmitter.
%
% In this example the variation in MCS over time due to the received SNR is
% controlled by the |threshold|, |rcaAttack| and |rcaRelease| parameters.
% The |rcaAttack| and |rcaRelease| are used as controls to smooth the rate
% changes, this is to avoid changing rates prematurely. Try changing the
% |rcaRelease| control to two. In this case, the decrease in MCS is slower
% to react when channel conditions are not good, resulting in higher BER.
%
% Try setting the |displayConstellation| to true in order to plot the
% equalized symbols per received packet, you can see the modulation scheme
% changing over time. Also try setting |walkSNR| to false in order to
% visualize the MCS change per packet. Here the variability in SNR is only
% caused by the radio channel, rather than the combination of channel and
% random walk.
%
% Further exploration includes using an alternate RCA scheme, more
% realistic MCS variation including changing number of space time streams,
% packet size and enabling STBC for subsequent transmitted packets.

%% Appendix
% This example uses the following helper functions:
%
% * <matlab:edit('helperFFTLength.m') helperFFTLength.m>
% * <matlab:edit('helperNoiseEstimate.m') helperNoiseEstimate.m>
% * <matlab:edit('helperReferenceSymbols.m') helperReferenceSymbols.m>
% * <matlab:edit('helperSubcarrierIndices.m') helperSubcarrierIndices.m>

%% Selected Bibliography
% # IEEE Std 802.11ac(TM)-2013 IEEE Standard for Information technology -
% Telecommunications and information exchange between systems - Local and
% metropolitan area networks - Specific requirements - Part 11: Wireless
% LAN Medium Access Control (MAC) and Physical Layer (PHY) Specifications -
% Amendment 4: Enhancements for Very High Throughput for Operation in Bands
% below 6 GHz.

%% Local Functions
% The following local functions are used in this example:
%
% * |processPacket|: Add channel impairments and decode receive packet
% * |plotResults|: Plot the simulation results

displayEndOfDemoMessage(mfilename)

function Y = processPacket(txWave,snrWalk,tgacChannel,cfgVHT)

% Pass the transmitted waveform through the channel, perform
% receiver processing, and SNR estimation.

chanBW = cfgVHT.ChannelBandwidth; % Channel bandwidth
% Set the following parameters to empty for an undetected packet
estimatedSNR = [];
eqDataSym = [];
noiseVarVHT = [];
rxPSDU = [];

% Get the number of occupied subcarriers in VHT fields
[vhtData,vhtPilots] = helperSubcarrierIndices(cfgVHT,'VHT');
Nst_vht = numel(vhtData)+numel(vhtPilots);
Nfft = helperFFTLength(cfgVHT); % FFT length

% Pass the waveform through the fading channel model
rxWave = tgacChannel(txWave);

% Create an instance of the AWGN channel for each transmitted packet
awgnChannel = comm.AWGNChannel;
awgnChannel.NoiseMethod = 'Signal to noise ratio (SNR)';
% Normalization
awgnChannel.SignalPower = 1/tgacChannel.NumReceiveAntennas;
% Account for energy in nulls
awgnChannel.SNR = snrWalk-10*log10(Nfft/Nst_vht);

% Add noise
rxWave = awgnChannel(rxWave);
rxWaveformLength = size(rxWave,1); % Length of the received waveform

% Recover packet
ind = wlanFieldIndices(cfgVHT); % Get field indices
pktOffset = wlanPacketDetect(rxWave,chanBW); % Detect packet


if ~isempty(pktOffset) % If packet detected
    % Extract the L-LTF field for fine timing synchronization
    LLTFSearchBuffer = rxWave(pktOffset+(ind.LSTF(1):ind.LSIG(2)),:);
    
    % Start index of L-LTF field
    finePktOffset = wlanSymbolTimingEstimate(LLTFSearchBuffer,chanBW);
    
    % Determine final packet offset
    pktOffset = pktOffset+finePktOffset;
    
    if pktOffset<15 % If synchronization successful
        % Extract L-LTF samples from the waveform, demodulate and
        % perform noise estimation
        LLTF = rxWave(pktOffset+(ind.LLTF(1):ind.LLTF(2)),:);
        demodLLTF = wlanLLTFDemodulate(LLTF,chanBW);
        
        % Estimate noise power in non-HT fields
        noiseVarVHT = helperNoiseEstimate(demodLLTF,chanBW,cfgVHT.NumSpaceTimeStreams,'Per Antenna');
        
        % Extract VHT-LTF samples from the waveform, demodulate and
        % perform channel estimation
        VHTLTF = rxWave(pktOffset+(ind.VHTLTF(1):ind.VHTLTF(2)),:);
        demodVHTLTF = wlanVHTLTFDemodulate(VHTLTF,cfgVHT);
        chanEstVHTLTF = wlanVHTLTFChannelEstimate(demodVHTLTF,cfgVHT);
        
        % Recover equalized symbols at data carrying subcarriers using
        % channel estimates from VHT-LTF
        [rxPSDU,~,eqDataSym] = wlanVHTDataRecover( ...
            rxWave(pktOffset + (ind.VHTData(1):ind.VHTData(2)),:), ...
            chanEstVHTLTF,mean(noiseVarVHT),cfgVHT);
        
        % SNR estimation per receive antenna
        powVHTLTF = mean(VHTLTF.*conj(VHTLTF));
        estSigPower = powVHTLTF-noiseVarVHT;
        estimatedSNR = 10*log10(mean(estSigPower./noiseVarVHT));
    end
end

% Set output
Y = struct( ...
    'RxPSDU',           rxPSDU, ...
    'EqDataSym',        eqDataSym, ...
    'RxWaveformLength', rxWaveformLength, ...
    'NoiseVar',         noiseVarVHT, ...
    'EstimatedSNR',     estimatedSNR);

end

function plotResults(ber,packetLength,snrMeasured,MCS,cfgVHT)
% Visualize simulation results

figure('Outerposition',[50 50 900 700])
subplot(4,1,1);
plot(MCS);
xlabel('Packet Number')
ylabel('MCS')
title('MCS selected for transmission')

subplot(4,1,2);
plot(snrMeasured);
xlabel('Packet Number')
ylabel('SNR')
title('Estimated SNR')

subplot(4,1,3);
plot(find(ber==0),ber(ber==0),'x')
hold on; stem(find(ber>0),ber(ber>0),'or')
if any(ber)
    legend('Successful decode','Unsuccessful decode')
else
    legend('Successful decode')
end
xlabel('Packet Number')
ylabel('BER')
title('Instantaneous bit error rate per packet')

subplot(4,1,4);
windowLength = 3; % Length of the averaging window
movDataRate = movsum(8*cfgVHT.APEPLength.*(ber==0),windowLength)./movsum(packetLength,windowLength)/1e6;
plot(movDataRate)
xlabel('Packet Number')
ylabel('Mbps')
title(sprintf('Throughput over last %d packets',windowLength))

end

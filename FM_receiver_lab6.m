function FM_receiver_lab6

%% PRINT FILE INFORMATION HYPERLINK TO COMMAND WINDOW
disp(['View file information for <a href="matlab: mfileinfo(''',mfilename,''')">',mfilename,'</a>']);

%% PARAMETERS (edit)
offline          = 0;                           % 0 = use RTL-SDR, 1 = import data
%offline_filepath = 'rec_data\wfm_mono.mat';    % path to FM signal
rtlsdr_id        = '0';                         % stick ID
rtlsdr_fc        = 102.7e6;                      % tuner centre frequency in Hz
rtlsdr_gain      = 80;                          % tuner gain in dB
rtlsdr_fs        = 2.4e6;                       % tuner sampling rate
rtlsdr_ppm       = 0;                           % tuner parts per million correction
rtlsdr_frmlen    = 256*25;                      % output data frame size (multiple of 5)
rtlsdr_datatype  = 'single';                    % output data type
deemph_region 	 = 'eu';                        % set to either eu or us
audio_fs         = 48e3;                        % audio output sampling rate
sim_time         = 60;                          % simulation time in seconds
fs_1             = 240e3;


%% CALCULATIONS (do not edit)
rtlsdr_frmtime = rtlsdr_frmlen/rtlsdr_fs;       % calculate time for 1 frame of data
if deemph_region == 'eu'                        % find de-emphasis filter coeff
    [num,den] = butter(1,3183.1/(audio_fs/2));
elseif deemph_region == 'us'
    [num,den] = butter(1,2122.1/(audio_fs/2));
else
    error('Invalid region for de-emphasis filter - must be either "eu" or "us"');
end


%% SYSTEM OBJECTS (do not edit)

% check if running offline
if offline == 1
    
    % link to an rtl-sdr data file
    obj_rtlsdr = import_rtlsdr_data(...
        'filepath', offline_filepath,...
        'frm_size', rtlsdr_frmlen,...
        'data_type',rtlsdr_datatype);
    
    % reduce sampling rate
    rtlsdr_fs = 240e3;
       
    
else
    
    % link to a physical rtl-sdr
    obj_rtlsdr = comm.SDRRTLReceiver(...
        rtlsdr_id,...
        'CenterFrequency', rtlsdr_fc,...
        'EnableTunerAGC', false,...
        'TunerGain', rtlsdr_gain,...
        'SampleRate', rtlsdr_fs, ...
        'SamplesPerFrame', rtlsdr_frmlen,...
        'OutputDataType', rtlsdr_datatype,...
        'FrequencyCorrection', rtlsdr_ppm);
    
    % fir decimator - fs = 2.4MHz downto 48kHz
    obj_decmtr_1 = dsp.FIRDecimator(...
        'DecimationFactor', 10,...
        'Numerator', fir1(63, 0.05));       % No. of taps is 63 and the cut off frequency is 40 Khz, converted to radians/samples/sec is 0.13
                                            % Cut off frequency is determined by the point on x-axis where the gain falls by 3db on y-axis
                                            % ((40KHz/2.4M)*pi) = 0.05
    
    obj_decmtr_2 = dsp.FIRDecimator(...
        'DecimationFactor', 5,...
        'Numerator', fir1(63, 0.0013));       % Cut off frequency is 15Khz as per mono FM broadcast receiver spectrum, ((15/240)*pi) = 0.0013    

end;

% iir de-emphasis filter
obj_deemph = dsp.IIRFilter(...
    'Numerator', num,...
    'Denominator', den);

% delay
obj_delay = dsp.Delay;

% audio output
obj_audio = dsp.AudioPlayer(audio_fs);

% spectrum analyzers
obj_spectrummod   = dsp.SpectrumAnalyzer(...
    'Name', 'Spectrum Analyzer Modulated',...
    'Title', 'Spectrum Analyzer Modulated',...
    'SpectrumType', 'Power density',...
    'FrequencySpan', 'Full',...
    'SampleRate', rtlsdr_fs);
obj_spectrumdemod = dsp.SpectrumAnalyzer(...
    'Name', 'Spectrum Analyzer Demodulated',...
    'Title', 'Spectrum Analyzer Demodulated',...
    'SpectrumType', 'Power density',...
    'FrequencySpan', 'Full',...
    'SampleRate', audio_fs);
obj_spectrumdiscrim = dsp.SpectrumAnalyzer('Name', 'Spectrum Analyzer Discriminator',... % spectrum analyzer to view output of frequency discriminator
    'Title', 'Spectrum Analyzer Discriminator',...
    'SpectrumType', 'Power density',...
    'FrequencySpan', 'Full',...
    'SampleRate', fs_1);

%% SIMULATION

% if using RTL-SDR, check first if RTL-SDR is active
if offline == 0    
    if ~isempty(sdrinfo(obj_rtlsdr.RadioAddress))
    else
        error(['RTL-SDR failure. Please check connection to ',...
            'MATLAB using the "sdrinfo" command.']);
    end
end

% reset run_time to 0 (secs)
run_time = 0;

% loop while run_time is less than sim_time
while run_time < sim_time
    
    % fetch a frame from obj_rtlsdr (live or offline)
    rtlsdr_data = step(obj_rtlsdr);
    
    % update 'modulated' spectrum analyzer window with new data
    step(obj_spectrummod, rtlsdr_data);
    
    
    %Implementing 1st stage decimator
    data_dec_1 = step(obj_decmtr_1, rtlsdr_data);
    
    % implement frequency discriminator
    discrim_delay = step(obj_delay,data_dec_1);
    discrim_conj  = conj(data_dec_1);
    discrim_pd    = discrim_delay.*discrim_conj;
    discrim_arg   = angle(discrim_pd);

    step(obj_spectrumdiscrim, discrim_arg);
    
    % decimate + de-emphasis filter data
    data_dec = step(obj_decmtr_2,discrim_arg);
    data_deemph = step(obj_deemph,data_dec);
    
    % update 'demodulated' spectrum analyzer window with new data
    step(obj_spectrumdemod, data_deemph);
    % output demodulated signal to speakers
    step(obj_audio,data_deemph);
    
    % update run_time after processing another frame
    run_time = run_time + rtlsdr_frmtime;
    
end

end

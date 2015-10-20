% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% %         IAPS PATTERN EXPRESSION PARADIGM SETTINGS    %
% %         WagerLab: Marianne 2014                      %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

%%%%%%%%%%%%%%%%%%%%%
%% SETTINGS
%%%%%%%%%%%%%%%%%%%%%
%% paths
imagedir=fullfile('C:','Users','mare8532','Desktop','IAPS','images');
canlabdir=fullfile('C:','Users','mare8532','Desktop','IAPS','CANLabRepos');
addpath(imagedir);addpath(genpath(canlabdir));
%% using physio?
use_biopac=1; %% if not using must uncomment WaitSecs in function
use_eyelink=1;
if use_biopac
    BIOPAC_PULSE_WIDTH = 4; %% this counts as TIME
else
    BIOPAC_PULSE_WIDTH = 0;
end
%% globals
% subj info file
% info.subid=input('Subject ID: ');
info.tr=.46; %not called
info.stimdurr=4;
% visual display
whichScreen = max(Screen('Screens'));
ntrial = 112;
rtrial = ntrial/2;
im_list=filenames(sprintf('%s\*',imagedir));
keyTrig=KbName('5%');
longITI=10; % first ITI before run
%% preallocate all arrays and structs for speed;
explog=zeros(rtrial+1,11);
%% open files for wriitng and saving
fname=sprintf('IAPSinfo_%d',info.subid);
datafilename = strcat('IAPS_',num2str(info.subid),'.txt'); % name of data file to write to
% check for existing result file to prevent accidentally overwriting
if fopen(datafilename, 'rt')~=-1
    fclose('all');
    error('Data file already exists! Choose a different subject number.');
else
    datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing
end
if fopen(fname, 'rt')~=-1
    fclose('all');
    error('Data file already exists! Choose a different subject number.');
end
%% rand num gen
rng('shuffle'); % Initialize the random number generator, but i dont use randi rand or randn
% iti durration list
iti=[];
for i = 3:12
    newtrial = ones(round(.5*rtrial),1)*i;
    iti = [iti; newtrial];
    rtrial = rtrial - length(newtrial);
end
randR1ITI=randperm(length(iti));
randR2ITI=randperm(length(iti));
for i=1:length(iti)
    r1ITI(i)=iti(randR1ITI(i));
    r2ITI(i)=iti(randR2ITI(i));
end
info.R1ITI=r1ITI';
info.R2ITI=r2ITI';
% image list
for i=1:length(im_list)
    [path, tag, ext] = fileparts(char(im_list(i)));
    images(i)=str2num(tag);%no ext
end
randomim=randperm(length(images));
for i=1:length(images)
    imageorder(i)=images(randomim(i));
end
imageorder=imageorder';
rtrial=length(imageorder)/2;
if rtrial ~= 56
    error('error in run 1 trial length... %d',rtrial)
end 
info.R1Images=imageorder(1:rtrial); 
info.R2Images=imageorder(rtrial+1:end); %%make sure this is num val now
%% instructions
instructions= sprintf('During this task you will see different images.\nYou will be asked questions about these images later.\nPlease remain still and alert, and get ready to begin.');
waitScan='Wait for scanner...';
% waitExper='Wait for experimenter...';
endrun='Thank you. You have completed the experiment.';
fixation='+';
%% preload images
for i=1:length(info.R1Images)
    r1imdata{i}=imread(sprintf('%d.jpg',info.R1Images(i)));
    r2imdata{i}=imread(sprintf('%d.jpg',info.R2Images(i)));
end
%%%%%%%%%%%%%%%%%%%%%
%% HARDWARE SET UP
%%%%%%%%%%%%%%%%%%%%%
%% copy from scanner PC
%% initialize biopac port
if use_biopac
    [ignore hn] = system('hostname'); hn=deblank(hn);
    addpath(genpath('\Program Files\MATLAB\R2012b\Toolbox\io32'));
    global BIOPAC_PORT; %#ok
    if strcmp(hn,'INC-DELL-001')
        BIOPAC_PORT = hex2dec('E050');
        trigger_biopac = str2func('TriggerBiopac3');
    else
        BIOPAC_PORT = digitalio('parallel','LPT2');
        addline(BIOPAC_PORT,0:7,'out');
        trigger_biopac = str2func('TriggerBiopac');
    end
end
%% initialize eyelink
if use_eyelink
    commandwindow;
    dummymode=0;
    try
         edfFile = sprintf('%d.EDF',info.subid);     
        % STEP 2
        % Open a graphics window on the main screen
        [window1, wRect]=Screen('OpenWindow', whichScreen, 0,[],32,2);
        Screen(window1,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        % STEP 3
        % Provide Eyelink with details about the graphics environment
        % and perform some initializations. The information is returned
        % in a structure that also contains useful defaults
        % and control codes (e.g. tracker state bit and Eyelink key values).
        el=EyelinkInitDefaults(window1);
        % STEP 4
        % Initialization of the connection with the Eyelink Gazetracker.
        % exit program if this fails.
        if ~EyelinkInit(dummymode)
            fprintf('Eyelink Init aborted. Cannot connect to Eyelink\n');
            % cleanup;
            % function cleanup
            Eyelink('Shutdown');
            Screen('CloseAll');
            commandwindow;
            return;
        end
        % check the version of the eye tracker & host software
%         sw_version = 0;
        [v vs]=Eyelink('GetTrackerVersion');
%         fprintf('Running experiment on a ''%s''tracker.\n', vs );
%         fprintf('tracker version v=%d\n', v);
        
        % open file to record data to
        eye = Eyelink('Openfile', edfFile);
        if eye~=0
            fprintf('Cannot create EDF file ''%s'' ', edffilename);
            % cleanup;
            % function cleanup
            Eyelink('Shutdown');
            Screen('CloseAll');
            commandwindow;
            return;
        end

        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox demo-experiment''');
        [width, height]=Screen('WindowSize', whichScreen);

        % STEP 5
        % SET UP TRACKER CONFIGURATION
        % Setting the proper recording resolution, proper calibration type,
        % as well as the data file content;
        Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);
        % set calibration type.
        Eyelink('command', 'calibration_type = HV9');
        % set parser (conservative saccade thresholds)
        
        % set EDF file contents using the file_sample_data and
        % file-event_filter commands
        % set link data thtough link_sample_data and link_event_filter
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        
        % check the software version
        % add "HTARGET" to record possible target data for EyeLink Remote
        if v>=4
            Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,HTARGET,GAZERES,STATUS,INPUT');
            Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');
        else
            Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT');
            Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
        end
        
        
        % allow to use the big button on the eyelink gamepad to accept the
        % calibration/drift correction target
        Eyelink('command', 'button_function 5 "accept_target_fixation"');
        
        % make sure we're still connected.
        if Eyelink('IsConnected')~=1 && dummymode == 0
            fprintf('not connected at step 5, clean up\n');
            % cleanup;
            % function cleanup
            Eyelink('Shutdown');
            Screen('CloseAll');
            commandwindow;
            return;
        end

        % STEP 6
        % Calibrate the eye tracker
        % setup the proper calibration foreground and background colors
        el.backgroundcolour = [125 125 125]; %changed to gray
        el.calibrationtargetcolour = [255 255 255];
        
        % parameters are in frequency, volume, and duration
        % set the second value in each line to 0 to turn off the sound
        el.cal_target_beep=[600 0.5 0.05];
        el.drift_correction_target_beep=[600 0.5 0.05];
        el.calibration_failed_beep=[400 0.5 0.25];
        el.calibration_success_beep=[800 0.5 0.25];
        el.drift_correction_failed_beep=[400 0.5 0.25];
        el.drift_correction_success_beep=[800 0.5 0.25];
        
        %Setting target size as recommended by Marcu at Eyelink
        el.calibrationtargetsize = 1.8;
        el.calibrationtargetwidth = 0.2;
        
        % you must call this function to apply the changes from above
        EyelinkUpdateDefaults(el);
        
        % Hide the mouse cursor;
        Screen('HideCursorHelper', window1);
        EyelinkDoTrackerSetup(el);
    catch exc
        %this "catch" section executes in case of an error in the "try" section
        %above.  Importantly, it closes the onscreen window if its open.
        % cleanup;
        % function cleanup
        getReport(exc,'extended')
        disp('EYELINK CAUGHT')
        Eyelink('Shutdown');
        Screen('CloseAll');
        commandwindow;
    end
end    %%%EYELINK DONE

%% record eyelink whole time
if use_eyelink
    status = Eyelink('Initialize');
    if status
        error('Eyelink is not communicating with PC. Its okay baby.');
    end
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.05);
    %         Eyelink('StartRecording', 1, 1, 1, 1);
    Eyelink('StartRecording');
    WaitSecs(0.1);
end
%% screen stuff
backgroundColor = 0; %black for image screen bk only
%%itiBkColor=87;itiTxtColor=0;
textColor = 87; %grey

%% save all subj specific params to this point
save(fname, 'info')
save tempspace







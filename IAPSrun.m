function IAPSrun(subID,run)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% %         IAPS PATTERN EXPRESSION PARADIGM FUNCTION    %
% %         WagerLab: Luke & Marianne         5/14       %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

% % takes subject ID, run number
if run==1
    info.subid=subID;
    IAPSsettings;
    endrun='You have completed this run, please wait for the experimenter.';
    flog=sprintf('IAPSlog_r1_%d',info.subid);
    ITI=r1ITI;imdata=r1imdata;
elseif run==2
    load tempspace;
    if subID ~= info.subid
        error('subject id mismatch')
    end
    flog=sprintf('IAPSlog_r2_%d',info.subid);
    run=2;ITI=r2ITI;imdata=r2imdata;
else
    error('Max run number is 2.');
end
%% Keyboard setup
KbName('UnifyKeyNames');

%% Screen setup
% will break with error message if Screen() can't run
AssertOpenGL;
Screen('Preference', 'Verbosity', 2) 
% whichScreen = max(Screen('Screens'));
[window1, rect] = Screen('Openwindow',whichScreen,backgroundColor,[],[],2);
% slack = Screen('GetFlipInterval', window1)/2;
W=rect(RectRight); % screen width
H=rect(RectBottom); % screen height
Screen(window1,'FillRect',backgroundColor);
Screen('TextSize', window1, 32);
Screen('Flip', window1);
HideCursor;

%% dummy call all mex functions for timing help
KbCheck;
WaitSecs(0.1);
GetSecs;
priorityLevel=MaxPriority(window1);
Priority(priorityLevel);

%% suppress output in matlab window
ListenChar(2); 


try
    %%%%%%%%%%%%%%%%%%%%%
    %% INSTRUCTIONS
    %%%%%%%%%%%%%%%%%%%%%
    DrawFormattedText(window1,instructions,'center','center',textColor);
    Screen('Flip',window1)
    while 1
        [~,~,keyCode] = KbCheck;
        if keyCode(KbName('space'))==1
            break
        end
    end
    DrawFormattedText(window1,waitScan,'center','center',textColor);
    Screen('Flip',window1)
    %% SCANNER TTL TRIG
    while 1
        [~,startTR,keyCode] = KbCheck;
        if keyCode(keyTrig)==1 %%modified for scanner
            break
        end
    end
    if use_eyelink; Eyelink('Message', 'ttl_start'); end
    %%%%%%%%%%%%%%%%%%%%%
    %% RUN1
    %%%%%%%%%%%%%%%%%%%%%
    Screen('DrawText',window1,fixation,(W/2), (H/2),textColor);
    if use_eyelink, Eyelink('Message', sprintf('R%d_startITI',run));end
    itiStart=Screen('Flip', window1);
    WaitSecs(longITI);itiEnd=GetSecs;
    explog(1,:)=[info.subid,run,0,0,startTR,0,0,0,itiStart,itiEnd,(itiStart-itiEnd)];
    for Trialnum=1:rtrial
        %draw stimulus
        tex=Screen('MakeTexture', window1, imdata{Trialnum});
        Screen('DrawTexture', window1, tex);
        if use_eyelink; Eyelink('Message', sprintf('R%d_TRIAL_%d', run,Trialnum)); end
        imStart=Screen('Flip', window1);
        if use_biopac;feval(trigger_biopac,BIOPAC_PULSE_WIDTH);end
%         WaitSecs(info.stimdurr-BIOPAC_PULSE_WIDTH);
        imEnd=GetSecs;
        %draw iti
        Screen('DrawText',window1,fixation,(W/2), (H/2),textColor);
        if use_eyelink; Eyelink('Message', sprintf('R%d_ITI_%d', run,Trialnum)); end
        itiStart=Screen('Flip', window1);
        WaitSecs(ITI(Trialnum));itiEnd=GetSecs;
        %save explog with each iteration
        explog(Trialnum+1,:)=[info.subid,run,Trialnum,info.R1Images(Trialnum),startTR,imStart,imEnd,(imStart-imEnd),itiStart,itiEnd,(itiStart-itiEnd)];
        save(flog,'explog');
    end
    %%%%%%%%%%%%%%%%%%%%%
    %% BREAK INSTRUCTIONS
    %%%%%%%%%%%%%%%%%%%%%
    DrawFormattedText(window1,endrun,'center','center',textColor);
    Screen('Flip',window1)
    while 1
        [~,~,keyCode] = KbCheck;
        if keyCode(KbName('space'))==1 
            break
        end
    end
   
catch
    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    psychrethrow(psychlasterror);    
end

if run==2
    %%%%%%%%%%%%%%%%%%%%%
    %% END EYELINK
    %%%%%%%%%%%%%%%%%%%%%
    if use_eyelink
        % STEP 8
        % End of Experiment; close the file first
        % close graphics window, close data file and shut down tracker
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.5);
        Eyelink('CloseFile');
        % download data file
        try
            fprintf('Receiving data file ''%s''\n', edfFile );
            status=Eyelink('ReceiveFile');
            if status > 0
                fprintf('ReceiveFile status %d\n', status);
            end
            if 2==exist(edfFile, 'file')
                fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
            end
        catch
            fprintf('Problem receiving data file ''%s''\n', edfFile );
        end
        % STEP 9
        % cleanup;
        % function cleanup
        Eyelink('Shutdown');
    end
end

%%%%%%%%%%%%%%%%%%%%%
%% CLEAN UP
%%%%%%%%%%%%%%%%%%%%%
Screen('CloseAll');
ShowCursor;
fclose('all');
Priority(0); 
sca;
ListenChar(0);% Restore keyboard output to Matlab
 
%%convert GAPED names in saved file

%             fprintf(datafilepointer,'%i %i %s %i %s %i %s %i %i %i\n', ...
%                 subNo, ...
%                 hand, ...
%                 phaselabel, ...
%                 trial, ...
%                 resp, ...
%                 objnumber(trial), ...
%                 char(objname(trial)), ...
%                 objtype(trial), ...
%                 ac, ...
%                 rt);


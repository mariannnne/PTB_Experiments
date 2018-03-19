%% Embodied Emotion Survey Item - Body Map
%  app asks user to indicate on the body map, where, if at all, they feel
%  sensation in their body in response to some image, event, or emotion.
%
%  this is the matlab version that will be made into a java app for
%  medialab
%
%  uses psychtoolbox
%
%  Records: coloring on bodymap, time on task & saved as a .mat file
%
%  by marianne, 2018

function BodyMapApp

% Screen Set up
% override sync tests for now
Screen('Preference', 'SkipSyncTests', 1);
% Open up a window on the screen and clear it.
whichScreen = max(Screen('Screens'));
[w,theRect] = Screen(whichScreen,'OpenWindow',0);
Screen(w,'TextSize',35);
line_color=[63 183 209 81];
% Get the size of the on screen window in pixels
[screenXpixels, screenYpixels] = Screen('WindowSize', w);
% Set priority for script execution to realtime priority:
priorityLevel=MaxPriority(w);
Priority(priorityLevel);

% Timing Set Up
WaitSecs(0.1);
GetSecs;

% Suppress output in matlab window
ListenChar(2); 

% Load bodymap image data
bmdata=imread('bodymap.jpg');

% Sub info - can you pass sub info in from medialab?
fname=sprintf('BodyMapDat_%s',datestr(now));
% datafilename = strcat(fname,'.txt'); % name of data file to write to
% datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing

%% text questions
Instruct='With the mouse, mark on the body map where, if at all, you feel sensation or emotion evoked by this video. \n \nClick to start. Hit space to finish.';
endexper='Thank you. Your Response has been recorded.';
%%%%%%%%%%%%%%%%%% TASK %%%%%%%%%%%%%%%%%%
try
    % display bodymap
    bmtex=Screen('MakeTexture', w, bmdata);
    Screen('DrawTextures', w, bmtex);
    
    % mouseaction
    % Move the cursor to the center of the screen
    theX = round(theRect(RectRight) / 2);
    theY = round(theRect(RectBottom) / 2);
    SetMouse(theX,theY,whichScreen);
    
    % instructions
    DrawFormattedText(w,Instruct,100,100,255,15);
    starttime=Screen('Flip', w, 0, 1);

    % click to start
    while (1)
        [~,~,buttons] = GetMouse(w);
        if buttons(1)
            break;
        end
    end

    % Loop and track the mouse, drawing the contour
    [theX,theY] = GetMouse(w);
    thePoints = [theX theY];
    Screen(w,'DrawLine',line_color,theX,theY,theX,theY); 
    % Set the 'dontclear' flag of Flip to 1 to prevent erasing the
    % frame-buffer:
    Screen('Flip', w, 0, 1);
    newPt=0;
    while (1)
        [~,startTime,keyCode] = KbCheck;
        if keyCode(KbName('space'))==1
            break
        else keepDraw=1;
        end

        while keepDraw
            [x,y,buttons] = GetMouse(w);
            if ~buttons(1)
                newPt=5;
                break;
            else
                thePoints = [thePoints ; x y]; %#ok<AGROW>
                [numPoints, ~]=size(thePoints);
                % Only draw the most recent line segment
                if ~newPt
                    Screen(w,'DrawLine',line_color,thePoints(numPoints-1,1),thePoints(numPoints-1,2),thePoints(numPoints,1),thePoints(numPoints,2));
                else
                    [theX,theY] = GetMouse(w);
                    Screen(w,'DrawLine',line_color,theX,theY,theX,theY);
                    % ...we ask Flip to not clear the framebuffer after flipping:
                    newPt=0;
                end
                Screen('Flip', w, 0, 1);
                theX = x; theY = y;
            end
        end
    end
    
    %save thePoints
    bmap_raw=thePoints;
    bmap_x_y=[thePoints(:,1),theRect(RectBottom)-thePoints(:,2)];
    time_on_task = GetSecs - startTime;
    
    %Screen('Flip', w);
    save IAPSbmap bmap_raw bmap_x_y
    save(fname,'time_on_task','bmap_raw','bmap_x_y');
    
catch
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
    save(fname,'time_on_task','bmap_raw','bmap_x_y');
end
%%%%%%%%%%%%%%%%%%%%%
%% END SCREEN
%%%%%%%%%%%%%%%%%%%%%
DrawFormattedText(w,endexper,'center',800,255);
Screen('Flip',w);
WaitSecs(1);

%%%%%%%%%%%%%%%%%%%%%
%% CLEAN UP
%%%%%%%%%%%%%%%%%%%%%
Screen('CloseAll');
Priority(0);
sca;
end
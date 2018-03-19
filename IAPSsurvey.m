function IAPSsurvey(subid)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
%         IAPS PATTERN EXPRESSION POST SCAN SURVEY     %
%         WagerLab: Luke & Marianne  2014              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

%% paths
% addpath(genpath('/Applications/Psychtoolbox'));
% addpath(genpath('~/Documents/MATLAB/CANLabRepos'));
% imagedir='~/Documents/MATLAB/images';
% bmdir='~/Documents/MATLAB/bodymap';
% addpath(imagedir);
% addpath(bmdir);

%% random number generator reset
rand('state',sum(100*clock)); %#ok
% %% images for loading
bmdata=imread('bodymap.jpg');
% im_list=filenames(sprintf('%s/*',imagedir));
% % image list
% for i=1:length(im_list)
%     [~, tag, ext] = fileparts(char(im_list(i)));
%     images{i}=sprintf('%s%s',tag);
% end
% randomim=randperm(length(images));
% for i=1:length(images)
%     imageorder(i)=images(randomim(i));
% end
% imageorder=imageorder';
surlog=[];bmap={};
% q=1;

% LOAD IN SUBJECT SPECIFIC IMAGE ORDER FROM SCANNER TASK
% MUST OPEN INC SERVER
incdir=fullfile('/','Volumes','Wager','ICAPS','ExperimentLogs',sprintf('%d',subid));
try
    addpath(genpath(incdir));
catch
    error('Did you connect to the INC server? Cntrl + K');
end
%% sub info
fname=sprintf('IAPSsurvey_%d',subid);
datafilename = strcat('IAPS_survey_',num2str(subid),'.txt'); % name of data file to write to
% check for existing result file to prevent accidentally overwriting
if fopen(datafilename, 'rt')~=-1
    fclose('all');
    disp('WARNING: Data file already exists! Do you want to overwrite it?');
    condOVER=input('1 = YES, 2 = I WANT TO CHANGE ID, 3 = I WANT TO START WHERE THIS SUBJECT LEFT OFF, 4 = QUIT: ');
    switch condOVER
        case 1
            datafilepointer = fopen(datafilename,'wt');
            startTrial=1;
            startQ=1;
        case 2
            subid=input('New Subject ID: ');
            fname=sprintf('IAPSsurvey_%d',subid);
            datafilename = strcat('IAPS_survey_',num2str(subid),'.txt');
            datafilepointer = fopen(datafilename,'wt');
            startTrial=1;startQ=1;
        case 3
            load(sprintf('%s',fname));
            startTrial=Im;
            startQ=Q;
        case 4
            fclose('all');
            error('Experimenter quit program.');
    end
else
    datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing
    startTrial=1;startQ=1;
end

logdir='/Volumes/Wager/ICAPS/ExperimentLogs';
sub_dir=filenames(sprintf('%s/%d',logdir,subid));
load(sprintf('IAPSinfo_%d',subid));
imageorder=[info.R1Images;info.R2Images];

%% screen settings
% PsychDefaultSetup(2);
screenNumber = max(Screen('Screens'));
%colors
% backgroundColor = 0; %black
% textColor = 87; %grey
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
textColor=white;

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
% Get the size of the on screen window in pixels
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
% Get the centre coordinate of the window in pixels
% [xCenter, yCenter] = RectCenter(windowRect);
ifi = Screen('GetFlipInterval', window);
% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
%     Screen('TextFont',window, 'Courier New');
Screen('TextSize',window, 30);
%     Screen('TextStyle',window, 1+2);

%%% configure
dspl.screenWidth = windowRect(3);
dspl.screenHeight = windowRect(4);
dspl.xcenter = dspl.screenWidth/2;
dspl.ycenter = dspl.screenHeight/2;
dspl.oscale(1).width = 964;
dspl.oscale(1).height = 252;
dspl.oscale(1).w = Screen('OpenOffscreenWindow',0);
% paint black
Screen('FillRect',dspl.oscale(1).w,0); %needed?
% add scale image
VASscale = imread('bartoshuk_scale.bmp'); % MAKE VAR
VAStex = Screen('MakeTexture',window,VASscale);
% Make a base Rect of 200 by 200 pixels
baseMark = [0 0 20 20];
vbl = Screen('Flip', window);
waitframes = 1;

% Keyboard setup
KbName('UnifyKeyNames');

%% initialize mex func
KbCheck;
WaitSecs(0.1);
GetSecs;
priorityLevel=MaxPriority(window);
Priority(priorityLevel);

%% text questions
Q1='How much does this image make you think of contamination or disease?';
Q2='How physically threatened do you feel?';
Q3='How intentional were the actions taking in the image?';
Q4='How pleasant is this image?'; %or unpleasant?
Q5='How immoral are the events depicted in is this image?';
Q6='Rate how much empathy you felt for the people or animals in this image.';
Q7='Did you get a sense of a story unfolding in this image?';
Q8='With the mouse, mark on this body map where, if at all, you feel the emotions evoked by this image.';
QList=1:8;
QStrList={Q1 Q2 Q3 Q4 Q5 Q6 Q7 Q8};
instruc='Please answer the following questions about the images you saw, as accurately as possible. Click to submit answers on the slider. To start, hit the space bar.';
endexper='Thank you. You have completed the experiment.';
hitspace='Hit Space Bar to Continue.';
%% scales
% S1='Not At All                                             Very Much';

dspl.oscale(1).rect = [...
    [dspl.xcenter dspl.ycenter]-[0.5*dspl.oscale(1).width 0.5*dspl.oscale(1).height] ...
    [dspl.xcenter dspl.ycenter]+[0.5*dspl.oscale(1).width 0.5*dspl.oscale(1).height]];
% shiftdown = ceil(dspl.screenHeight*0);
% dspl.oscale(1).rect = dspl.oscale(1).rect + [0 shiftdown 0 shiftdown];
% add title
% Screen('TextSize',dspl.oscale(1).w,50);
% DrawFormattedText(dspl.oscale(1).w,...
%     'OVERALL INTENSITY RATING',...
%     'center',dspl.ycenter-270,255);
% determine cursor parameters for all scales
cursor.xmin = dspl.oscale.rect(1) + 123;
cursor.width = 700;
cursor.xmax = cursor.xmin + cursor.width;
cursor.size = 8;
cursor.center = cursor.xmin + ceil(cursor.width/2);
cursor.y = dspl.oscale.rect(4) - 41;
cursor.labels = cursor.xmin + [10 42 120 249 379];

qtextPos=550;
qTextSize=80;

%%%%%%%%%%%%%%%%%% TASK %%%%%%%%%%%%%%%%%%
%% instructions
try
    DrawFormattedText(window,instruc,'center','center',textColor,50);
    Screen('Flip',window)
    while 1
        [~,startTime,keyCode] = KbCheck;
        if keyCode(KbName('space'))==1
            break
        end
    end
    %% task
    % randomize q order
    % static image order
    
    %rand gen order of ques and store in array ques(i)
    randQ=randperm(length(QList));
    for x=1:length(QList)
        QOrder(x)=QList(randQ(x));
    end
    
    for j=startQ:length(QOrder);
        %clear buff
        %put crosshairs
        DrawFormattedText(window,hitspace,'center','center',textColor);
        Screen('Flip',window,0)
        while 1
            [~,~,keyCode] = KbCheck;
            if keyCode(KbName('space'))==1
                break
            end
        end
        
        
        for i=startTrial:length(imageorder)
            %load, resize, and place image
            imdata=imread(sprintf('%d%s',imageorder(i),'.jpg'));
            tex=Screen('MakeTexture', window, imdata);
            [s1, s2, ~] = size(imdata);aspectRatio = s2 / s1;
            heightScalers = linspace(1, 0.2, 10);
            imageHeights = screenYpixels .* heightScalers;
            imageWidths = imageHeights .* aspectRatio;
            currImage=imageorder(i);
            % Number of images
            %numImages = numel(heightScalers);
            theRect = [0 0 imageWidths(7) imageHeights(7)];
            dstRects=CenterRectOnPointd(theRect, screenXpixels/2, screenYpixels/3.5);
            
            [s1, s2, ~] = size(bmdata);aspectRatio = s2 / s1;
            heightScalers = linspace(1, 0.2, 10);
            imageHeights = screenYpixels .* heightScalers;
            imageWidths = imageHeights .* aspectRatio;
            bRect = [0 0 imageWidths(5) imageHeights(5)];
            bmRects=CenterRectOnPointd(bRect, 1100, screenYpixels/3);
            
            
            qtext=char(QStrList(QOrder(j)));
            DrawFormattedText(window,qtext,'center',qtextPos,textColor,qTextSize);
            Screen('DrawTextures', window, tex, [], dstRects);
            
            if QOrder(j)==8;
                %display bodymap
                bmtex=Screen('MakeTexture', window, bmdata);
                Screen('DrawTextures', window, bmtex, [], bmRects);
                
                %mouseaction
                % Move the cursor to the center of the screen (over image)
                %             theX = windowRect(RectRight)/2;
                %             theY = windowRect(RectBottom)/2;
                theX=1300;theY=300;
                SetMouse(theX,theY);
                Screen(window,'DrawText','Click to start. Hit space to finish.',50,50,255);
                Screen('Flip', window, 0, 1);
                while (1)
                    [~,~,buttons] = GetMouse(window);
                    if buttons(1)
                        break;
                    end
                end
                [theX,theY] = GetMouse(window);
                thePoints = [theX theY];
                %             Screen(window,'DrawLine',120,theX,theY,theX,theY,5.5);
                Screen('DrawLine',window,[63 183 209 81],theX,theY,theX,theY,7); %doesnt change prop
                Screen('Flip', window, 0, 1);
                newPt=0;
                while (1)
                    [~,startTime,keyCode] = KbCheck;
                    if keyCode(KbName('space'))==1
                        break
                    else keepDraw=1;
                    end
                    while keepDraw
                        [x,y,buttons] = GetMouse(window);
                        if ~buttons(1)
                            newPt=5;
                            break;
                        else
                            thePoints = [thePoints ; x y]; %#ok<AGROW>
                            [numPoints, ~]=size(thePoints);
                            % Only draw the most recent line segment: This is possible,
                            % because...
                            if ~newPt
                                Screen('DrawLine',window,[63 183 209 81],thePoints(numPoints-1,1),thePoints(numPoints-1,2),thePoints(numPoints,1),thePoints(numPoints,2),7);
                            else
                                [theX,theY] = GetMouse(window);
                                Screen('DrawLine',window,[63 183 209 81],theX,theY,theX,theY,7);
                                % ...we ask Flip to not clear the framebuffer after flipping:
                                newPt=0;
                            end
                            Screen('Flip', window, 0, 1);
                            theX = x; theY = y;
                        end
                    end
                end
                %save thePoints
                bmap{i}=thePoints;
                Screen('Flip', window);
                
                
            else %VAS scale
                
                % display scale
                Screen('DrawTextures',window,VAStex,[],dspl.oscale(1).rect);
                Screen('DrawTextures', window, tex, [], dstRects); %try textures
                % where to start the mouse MAKE RAND
                cursor.x = cursor.xmin;
                theX=dspl.xcenter;theY=dspl.ycenter;
                SetMouse(theX,theY);
                %                 centeredMarksc=CenterRectOnPointd(baseMark, cursor.x, cursor.y);
                Screen('Flip', window, 0, 1);
                getRating=1;
                while getRating
                    [x,y,buttons] = GetMouse(window);
                    if buttons(1)
                        getRating=0;
                        break;
                    end
                    cursor.x = x;
                    % check bounds
                    if cursor.x > cursor.xmax
                        cursor.x = cursor.xmax;
                    elseif cursor.x < cursor.xmin
                        cursor.x = cursor.xmin;
                    end
                    
                    centeredMark = CenterRectOnPointd(baseMark, cursor.x, cursor.y);
                    
                    %                     DrawFormattedText(window,qtext,'center',700,textColor,50);
                    DrawFormattedText(window,qtext,'center',qtextPos,textColor,qTextSize);
                    Screen('DrawTextures',window,VAStex,[],dspl.oscale(1).rect);
                    Screen('DrawTextures', window, tex, [], dstRects); %try textures
                    Screen('FillRect', window, [128 128 128], centeredMark);
                    vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
                end
                
                qX=cursor.x;
                qresp=(cursor.x-cursor.xmin)/7;
                [r,~]=size(surlog);
                surlog(r+1,:)=[subid, startTime,currImage,QOrder(j),qX,qresp,vbl];
                WaitSecs(.25);
            end
            startTrial=1;
            Q=j;
            Im=i;
            save(fname,'surlog','bmap','imageorder','Q','Im');
            Screen('Close', tex);
        end
        %             [~,~,quitCode] = KbCheck;
        %             if quitCode(20)==1
        %                 error('Experimenter Quit Survey.')
        %                 q=0;
        %                 break
        %             end
        
        %must clear buffer of images or this script will crash your memory
        %         Screen('CloseAll');
        %         Screen('Close', tex);
    end
catch
    Screen('CloseAll');
    fclose('all');
    Priority(0);
    psychrethrow(psychlasterror);
    save(fname,'surlog','bmap','imageorder','Q','Im');
end
%%%%%%%%%%%%%%%%%%%%%
%% END SCREEN
%%%%%%%%%%%%%%%%%%%%%
DrawFormattedText(window,endexper,'center','center',textColor);
Screen('Flip',window)
while 1
    [~,~,keyCode] = KbCheck;
    if keyCode(KbName('space'))==1
        break
    end
end

%%%%%%%%%%%%%%%%%%%%%
%% CLEAN UP
%%%%%%%%%%%%%%%%%%%%%
incsave=fullfile(sprintf('%s',incdir),sprintf('%s',fname));
save(incsave,'surlog','bmap','imageorder');
Priority(0);
Screen('CloseAll');
fclose('all');
sca;

end

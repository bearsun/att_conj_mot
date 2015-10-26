function searching
% pre and post test for this learning exp
% 10/20/15 by Liwei

%% initialize everything
clc;
%AssertOpenGL;
%Priority(1);
rng('shuffle');
sid = 0;

global monitorh
global distance
global rect
monitorh=30; %12;% in cm
distance=55; %25;% in cm
screenrect = [1280, 0, 2880, 1200];
% colors
red = [255 0 0];
green = [0 255 0];
blue = [0 0 255];
yellow = [255 255 0];

% % stu .5
% stired = [177 88 88];
% stigreen = [68 136 68];
% stiblue = [103 103 206];
% stiyellow = [121 121 61];
% stu .8
% stired = [206 41 41];
% stigreen = [28 139 28];
% stiblue = [51 51 255];
% stiyellow = [109 109 22];
colors = [red;green;blue;yellow];

colorsq = [ones(6,1),perms(2:4)]; % control red color


% parameters
nblocks = 8;
ntrialsperb = 24;
ntrials = nblocks * ntrialsperb;
searchtime = 4; % 4s to search
nframes = searchtime * 60;
radius = 80;
nrings=3;
stimPerRing=8;
nballs=nrings*stimPerRing;

% for color from q1 to q4
startAngle = [0 90 180 270];
arcAngle = 90;
ballrect = [0,0,radius,radius];

%black = BlackIndex(sid);
white = [255 255 255];
gray = [128 128 128];
bgcolor = gray;
fixsi = 8;

kesc = KbName('Escape');
kn0 = KbName('KP_Insert');
kn1 = KbName('KP_End');
kn2 = KbName('KP_Down');
kn3 = KbName('KP_Next');
possiblekn = [kn0; kn1; kn2; kn3];
disp('parameters_initiated');

%% random target position with no repeat
targetoptions=[1:nballs,zeros(1,stimPerRing)]; %catch trials 25%, each ring 25%
repeat=1;
while repeat
    targetindex=BalanceTrials(ntrials,1,targetoptions);
    targetindex=(reshape(targetindex,ntrialsperb,nblocks))' ;
    repeat=0;
    for i=2:ntrialsperb
        w=targetindex(:,i-1)==targetindex(:,i);
        if any(w)&&any(targetindex(w,i-1)~=0)
            repeat=1;
            break;
        end
    end
end

disp('pass_rng_target_pos');


%% Login screen
prompt = {'Outputfile', 'Subject', 'age', 'gender','group','session'};
defaults = {'Training', '99', '18','M','1','1'};
answer = inputdlg(prompt, 'Training', 2, defaults);
[output, subnum, subage, gender,group,session] = deal(answer{:});
outputname = [output '-' subnum gender subage '-g' group '-s' session];
if exist(outputname,'file')==2&&(str2double(subnum)~=99)
    fileproblem = input('That file already exists! Append a .x (1), overwrite (2), or break (3/default)?');
    if isempty(fileproblem) || fileproblem==3
        return;
    elseif fileproblem==1
        outputname = [outputname '.x'];
    end
end
outfile = fopen(outputname,'w');
fprintf(outfile,'%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t \n', ...
    'subnum', 'subage', 'gender', 'group', 'session', 'block', 'trial', 'itarget', 'answer', 'keypressed', ...
    'cor','rt');
disp('data_file_opened');

% target color combination is determined by the subnum
ctarget = mod(str2double(subnum)-1, size(colorsq, 1)) + 1;
targetcolor = colors(colorsq(ctarget,:),:);
% distractor color is from the rest of 5 colors
discolor = targetcolor([1,3,4,2],:);
disp('target:');
disp(targetcolor);
disp('distractor:');
disp(discolor);

%% initialize window
[mainwin,rect] = Screen('OpenWindow', sid, bgcolor,screenrect);

% open buffer
buffers = NaN(nframes,1);
for i = 1:nframes
    [buffers(i),~] = Screen('OpenOffscreenWindow', mainwin, bgcolor);
end

%% build up position arrays
% basic screen
center = [(rect(3)-rect(1))/2, (rect(4)-rect(2))/2];
fixRect = CenterRect([0 0 fixsi fixsi], rect);

% construct stimuli
corticalStimSize=5;%in mm
proximalStimDist=2;% in degrees!!
stimSeparation=1; %in degrees, to be scaled
jitterDistance=.08;%in degrees; to be scaled

%empty variable
stimLocation = NaN(nblocks,ntrialsperb,nrings,stimPerRing,4);
stimSize=NaN(nrings,4);
eccentricity=NaN(nrings);

separationAngle=360/stimPerRing;
compass = separationAngle:separationAngle:360; %rectangle
jpix=ang2pix(jitterDistance);

%enlarge for placeholder
%jph=[-jpix,-jpix,jpix,jpix]';

%ecc in degree to size
for ring=1:nrings
    ecc=proximalStimDist+stimSeparation*ring^2;
    gratingSize=CorticalScaleFactor(corticalStimSize,ecc);
    stimSize(ring,:)=[0 0 1 1] * ang2pix(gratingSize);
    eccentricity(ring)=ang2pix(ecc);
end

%generate positions
for block=1:nblocks
    for trial=1:ntrialsperb
        for ring=1:nrings
            for stimIndex=1:stimPerRing
                stimX=eccentricity(ring)*cosd(compass(stimIndex));
                stimY=eccentricity(ring)*sind(compass(stimIndex));
                stimLocation(block,trial,ring,stimIndex,:)=CenterRectOnPoint(stimSize(ring,:),center(1)+stimX,center(2)+stimY);
            end
        end
    end
end

tarpos = [center(1)-200, center(2) + 100];
dispos = [center(1)+200, center(2) + 100];

disp('pass_position_generation');

%% exp start
for block = 1:nblocks
   DrawFormattedText(mainwin, ['Block No.', num2str(block)], 'center','center',white);
   Screen('DrawText', mainwin, 'Target', tarpos(1)-30, tarpos(2)-70, white);
   Screen('DrawText', mainwin, 'Distractor', dispos(1)-45, dispos(2)-70, white);
   t1 = GetSecs;
    % target left
    Screen('FillArc', mainwin, targetcolor(1,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(1), arcAngle);
    Screen('FillArc', mainwin, targetcolor(2,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(2), arcAngle);
    Screen('FillArc', mainwin, targetcolor(3,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(3), arcAngle);
    Screen('FillArc', mainwin, targetcolor(4,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(4), arcAngle);
    % distractor right
    Screen('FillArc', mainwin, discolor(1,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(1), arcAngle);
    Screen('FillArc', mainwin, discolor(2,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(2), arcAngle);
    Screen('FillArc', mainwin, discolor(3,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(3), arcAngle);
    Screen('FillArc', mainwin, discolor(4,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(4), arcAngle);
    Screen('Flip',mainwin);
    disp(GetSecs-t1);
    KbStrokeWait;
    
    for trial = 1:ntrialsperb
        % prepare and wait to start
        t2 = GetSecs;
        ti=targetindex(block,trial);
        disp(ti);
        tring=ceil(ti/stimPerRing);
        tpos=ti-(tring-1)*stimPerRing;
        jit=zeros(nrings,stimPerRing,4);
        for i = 1:nframes
            Screen('FillRect', buffers(i), bgcolor);
            Screen('FillRect', buffers(i), white, fixRect);
            for ring=1:nrings
                for stimIndex=1:stimPerRing
                    if ~mod(i,10)
                        xjit=jpix*(rand*2-1);
                        yjit=(-1)^randi(2)*sqrt(jpix^2-xjit^2);
                        jit(ring,stimIndex,:)=[xjit;yjit;xjit;yjit];
                    end
                    if stimIndex==tpos&&ring==tring
                        Screen('FillArc',buffers(i),targetcolor(1,:),squeeze(stimLocation(block,trial,ring,stimIndex,:))+squeeze(jit(ring,stimIndex,:)),startAngle(1),arcAngle);
                        Screen('FillArc',buffers(i),targetcolor(2,:),squeeze(stimLocation(block,trial,ring,stimIndex,:))+squeeze(jit(ring,stimIndex,:)),startAngle(2),arcAngle);
                        Screen('FillArc',buffers(i),targetcolor(3,:),squeeze(stimLocation(block,trial,ring,stimIndex,:))+squeeze(jit(ring,stimIndex,:)),startAngle(3),arcAngle);
                        Screen('FillArc',buffers(i),targetcolor(4,:),squeeze(stimLocation(block,trial,ring,stimIndex,:))+squeeze(jit(ring,stimIndex,:)),startAngle(4),arcAngle);
                    else
                        Screen('FillArc',buffers(i),discolor(1,:),squeeze(stimLocation(block,trial,ring,stimIndex,:))+squeeze(jit(ring,stimIndex,:)),startAngle(1),arcAngle);
                        Screen('FillArc',buffers(i),discolor(2,:),squeeze(stimLocation(block,trial,ring,stimIndex,:))+squeeze(jit(ring,stimIndex,:)),startAngle(2),arcAngle);
                        Screen('FillArc',buffers(i),discolor(3,:),squeeze(stimLocation(block,trial,ring,stimIndex,:))+squeeze(jit(ring,stimIndex,:)),startAngle(3),arcAngle);
                        Screen('FillArc',buffers(i),discolor(4,:),squeeze(stimLocation(block,trial,ring,stimIndex,:))+squeeze(jit(ring,stimIndex,:)),startAngle(4),arcAngle);
                    end
                end
            end
        end
        disp(t2-GetSecs);
        Screen('FillRect', mainwin, white, fixRect);
        Screen('Flip', mainwin);
        KbStrokeWait;
        
        keypressed =NaN;
        rt = NaN;
        % show
        Screen('DrawTexture', mainwin, buffers(1));
        Screen('Flip', mainwin);
        t1 = GetSecs;
        for i = 2:nframes
            [keyIsDown, secs, keyCode] = KbCheck;
            FlushEvents('keyDown');
            if keyIsDown
                nKeys = sum(keyCode);
                if nKeys == 1
                    if keyCode(kesc)
                        session_end;return
                    elseif any(keyCode(possiblekn))
                        keypressed=find(keyCode);
                        rt = secs - t1;
                        break;
                    end
                end
            end
            Screen('DrawTexture', mainwin, buffers(i));
            Screen('Flip', mainwin);
        end
        
        respring = find(ismember(possiblekn,keypressed));
        if respring == tring
            cor = 1;
            Screen('FillRect', mainwin, green, fixRect);
        else
            Screen('FillRect', mainwin, red, fixRect);
            cor = 0;
        end
        fprintf(outfile,'%s\t %s\t %s\t %s\t %s\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t \n', ...
            subnum, subage, gender, group, session, block, trial, ti, possiblekn(tring+1), keypressed, ...
            cor, rt);
        Screen('Flip', mainwin);

    end
end
session_end;

    function session_end
        %         if ~debug
        %             Eyelink('Message','session_end');
        %             Eyelink('Stoprecording');
        %             Eyelink('CloseFile');
        %             Eyelink('ReceiveFile');
        %         end
        fclose(outfile);
        %         ShowCursor;
        sca;
        return
    end

    function pixels=ang2pix(ang)
        pixpercm=rect(4)/monitorh;
        pixels=tand(ang/2)*distance*2*pixpercm;
    end

    function stimSize=CorticalScaleFactor(corticalSize,eccentricity)
        M=.065*eccentricity+.054;
        stimSize=M*corticalSize;
    end
    
end
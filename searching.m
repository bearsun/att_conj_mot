function searching(debug)
% pre and post test for this learning exp
% 10/20/15 by Liwei

%% initialize everything
clc;
b = system('xrandr --screen 1 --output CRT2 --mode 1024x768 --rate 60');

global ptb_RootPath %#ok<NUSED>
%AssertOpenGL;
%Priority(1);
rng('shuffle');
sid = 1;

global monitorh
global distance
global rect
monitorh=30; %12;% in cm
distance=55; %25;% in cm
%screenrect = [1024 0 2048 768];
% colors
red = [255 0 0];
green = [0 255 0];
%blue = [0 0 255];
%yellow = [255 255 0];

% stu .5
% stired = [177 88 88];
% stigreen = [68 136 68];
% stiblue = [103 103 206];
% stiyellow = [121 121 61];
% stu .8
% stired = [206 41 41];
% stigreen = [28 139 28];
% stiblue = [51 51 255];
% stiyellow = [109 109 22];
% colors = [stired;stigreen;stiblue;stiyellow];


% parameters
nblocks = 8;
ntrialsperb = 25;
ntrials = nblocks * ntrialsperb;
searchtime = 5; % 5s to search
nframes = searchtime * 60;
radius = 40;
nrings=4;
stimPerRing=8;
nballs=nrings*stimPerRing;

% for color from q1 to q4
startAngle = [0 90 180 270];
arcAngle = 90;
ballrect = [0,0,radius*2,radius*2];

%black = BlackIndex(sid);
white = [255 255 255];
%gray = [128 128 128];
black = [0 0 0];
bgcolor = black;
fixsi = 8;

kesc = KbName('Escape');
kspace = KbName('space');
kreturn = KbName('Return');
kback = KbName('BackSpace');
kleftctrl = KbName('Control_L');
kn0 = KbName('KP_Insert');
kn1 = KbName('KP_End');
kn2 = KbName('KP_Down');
kn3 = KbName('KP_Next');
kn4 = KbName('KP_Enter');
possiblekn = [kn0; kn1; kn2; kn3; kn4];
disp('parameters_initiated');

%% random target position with no repeat
targetoptions=[1:nballs,zeros(1,stimPerRing)]; %catch trials 20%, each ring 20%
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
abbreviatedFilename=[subnum,'_',datestr(now,'mmdd')];
disp('data_file_opened');


%% color issue
colorsq = [ones(6,1),perms(2:4)]; % control red color
% I will only use 4 stimuli in the colorsq
% 2 distractors with blue in the opposite side of red
cdisC = colorsq(1,:);
cdisD = colorsq(5,:);
% two pairs of target, need to counterbalanced between subjects
targetpair1 = colorsq([2,4],:);
targetpair2 = colorsq([6,3],:);
ksession=str2double(session);

if ksession==1&&~exist([pwd,'/subinfo/',subnum,'_info.mat'],'file')
    rg=IsoRGBY;
    colors = rg;
    switch mod(str2double(subnum),4)
        case 1
            ctargetA = targetpair1(1,:);
            ctargetB = targetpair1(2,:);
        case 2
            ctargetA = targetpair1(2,:);
            ctargetB = targetpair1(1,:);
        case 3
            ctargetA = targetpair2(1,:);
            ctargetB = targetpair2(2,:);
        case 0
            ctargetA = targetpair2(2,:);
            ctargetB = targetpair2(1,:);
        otherwise
            error('wrong subnum or code');
    end
    save([pwd,'/subinfo/',subnum,'_info.mat'],'rg','ctargetA','ctargetB','cdisC','cdisD');
else
    rg=load([pwd,'/subinfo/',subnum,'_info.mat']);
    
    colors = rg.rg;
    ctargetA = rg.ctargetA;
    ctargetB = rg.ctargetB;
end

%% four kind of trials:
% 1:Target A, Dis C
% 2:Target B, Dis C
% 3:Target A, Dis D
% 4:Target B, Dis D

colorpairs = [ctargetA, cdisC;
    ctargetB, cdisC;
    ctargetA, cdisD;
    ctargetB, cdisD];

% to make sure the within session learning is the same for each condition
% for each target/distractor, I arrange the 8 blocks as 14233241.
% the whole will looks like:
% A C
% B D
% B C
% A D
% A D
% B C
% B D
% A C
% since we are comparing pre/post, if we keep the order exactly the same,
% the schedule effect shouldn't matter (AD repeats one time in the middle)

orderblock = [1 4 2 3 3 2 4 1];

%% initialize window
[mainwin,rect] = Screen('OpenWindow', sid, bgcolor);

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
proximalStimDist=.8;% in degrees!!
stimSeparation=.6; %in degrees, to be scaled
jitterDistance=.05;%in degrees; to be scaled

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calibration
if ~debug
    Eyelink('Shutdown');
    Eyelink('Initialize');
    HideCursor;
    Screen('Fillrect', mainwin, black)
    Screen('Flip',mainwin);
    
    Eyelink('StartSetup')
    pause(2)
    
    
    whichKey=0;
    
    keysWanted=[kspace kreturn kback];
    FlushEvents('KeyDown');
    while 1
        pressed = 0;
        while pressed == 0
            [pressed, ~, kbData] = KbCheck;
        end;
        
        for keysToCheck = 1:length(keysWanted)
            if kbData(keysWanted(keysToCheck)) == 1
                
                keyPressed = keysWanted(keysToCheck);
                if keyPressed == kback
                    whichKey=9;
                    FlushEvents('KeyDown');
                    WaitSecs(.1)
                elseif keyPressed == kspace
                    whichKey=1;
                    FlushEvents('KeyDown');
                    WaitSecs(.1)
                elseif keyPressed == kreturn
                    whichKey=5;
                    FlushEvents('KeyDown');
                    WaitSecs(.1)
                else
                end
                FlushEvents('KeyDown');
                
            end;
        end;
        
        if whichKey == 1
            whichKey=0;
            [~, tx, ty] = Eyelink('TargetCheck');
            tx=tx*.64;
            ty=ty*.64;
            Screen('FillRect', mainwin ,white, [tx-20 ty-5 tx+20 ty+5]);
            Screen('FillRect', mainwin ,white, [tx-5 ty-20 tx+5 ty+20]);
            Screen('Flip', mainwin);
        elseif whichKey == 5
            whichKey=0;
            Eyelink('AcceptTrigger');
        elseif whichKey == 9
            break;
        end
    end;
    status = Eyelink('OpenFile',abbreviatedFilename);
    if status
        error(['openfile error, status: ', num2str(status)]);
    end
    Eyelink('StartRecording');
end


%% exp start
if ~debug
    Eyelink('Message','session_start');
end
for block = 1:nblocks
    colorpair = colorpairs(orderblock(block),:);
    targetcolor = colors(colorpair(1:4),:);
    discolor = colors(colorpair(5:8),:);
    disp('target:');
    disp(targetcolor);
    disp('distractor:');
    disp(discolor);
    
    DrawFormattedText(mainwin, ['Block No.', num2str(block)], 'center','center',white);
    Screen('DrawText', mainwin, 'Target', tarpos(1)-20, tarpos(2)-70, white);
    Screen('DrawText', mainwin, 'Distractor', dispos(1)-25, dispos(2)-70, white);
    t1 = GetSecs;
    % target left
    Screen('FillArc', mainwin, targetcolor(1,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(1), arcAngle);
    Screen('FillArc', mainwin, targetcolor(2,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(2), arcAngle);
    Screen('FillArc', mainwin, targetcolor(3,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(3), arcAngle);
    Screen('FillArc', mainwin, targetcolor(4,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(4), arcAngle);
    Screen('DrawLine', mainwin, black, tarpos(1) - radius, tarpos(2), tarpos(1) + radius, tarpos(2));
    Screen('DrawLine', mainwin, black, tarpos(1), tarpos(2) - radius, tarpos(1), tarpos(2) + radius);
    % distractor right
    Screen('FillArc', mainwin, discolor(1,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(1), arcAngle);
    Screen('FillArc', mainwin, discolor(2,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(2), arcAngle);
    Screen('FillArc', mainwin, discolor(3,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(3), arcAngle);
    Screen('FillArc', mainwin, discolor(4,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(4), arcAngle);
    Screen('DrawLine', mainwin, black, dispos(1) - radius, dispos(2), dispos(1) + radius, dispos(2));
    Screen('DrawLine', mainwin, black, dispos(1), dispos(2) - radius, dispos(1), dispos(2) + radius);
    Screen('Flip',mainwin);
    disp(GetSecs-t1);
    KbStrokeWait;
    
    for trial = 1:ntrialsperb
        % prepare and wait to start
        t2 = GetSecs;
        ti=targetindex(block,trial);
        disp(ti);
        tring=ceil(ti/stimPerRing);
        disp(tring);
        tpos=ti-(tring-1)*stimPerRing;
        disp(tpos);
        jit=zeros(nrings,stimPerRing,4);
        for i = 1:nframes
            Screen('FillRect', buffers(i), bgcolor);
            Screen('FillRect', buffers(i), white, fixRect);
            for ring=1:nrings
                for stimIndex=1:stimPerRing
                    if ~mod(i,6)
                        xjit=jpix*(rand*2-1);
                        yjit=(-1)^randi(2)*sqrt(jpix^2-xjit^2);
                        jit(ring,stimIndex,:)=[xjit;yjit;xjit;yjit];
                    end
                    loc = squeeze(stimLocation(block,trial,ring,stimIndex,:))+squeeze(jit(ring,stimIndex,:));
                    r = (loc(3)-loc(1))/2;
                    if stimIndex==tpos&&ring==tring
                        Screen('FillArc',buffers(i),targetcolor(1,:),loc,startAngle(1),arcAngle);
                        Screen('FillArc',buffers(i),targetcolor(2,:),loc,startAngle(2),arcAngle);
                        Screen('FillArc',buffers(i),targetcolor(3,:),loc,startAngle(3),arcAngle);
                        Screen('FillArc',buffers(i),targetcolor(4,:),loc,startAngle(4),arcAngle);
                    else
                        Screen('FillArc',buffers(i),discolor(1,:),loc,startAngle(1),arcAngle);
                        Screen('FillArc',buffers(i),discolor(2,:),loc,startAngle(2),arcAngle);
                        Screen('FillArc',buffers(i),discolor(3,:),loc,startAngle(3),arcAngle);
                        Screen('FillArc',buffers(i),discolor(4,:),loc,startAngle(4),arcAngle);
                    end
                    Screen('DrawLine', buffers(i), black, loc(1), loc(2) + r, loc(3), loc(2) + r);
                    Screen('DrawLine', buffers(i), black, loc(1) + r, loc(2), loc(1) + r, loc(4));
                end
            end
        end
        disp(t2-GetSecs);
        Screen('FillRect', mainwin, white, fixRect);
        Screen('Flip', mainwin);
        
        while 1 %wait to start
            [keyIsDown, ~, keyCode] = KbCheck;
            FlushEvents('keyDown');
            if keyIsDown
                nKeys = sum(keyCode);
                if nKeys == 1
                    if keyCode(kesc)
                        session_end;return
                    elseif keyCode(kspace)
                        break;
                    elseif keyCode(kleftctrl)
                        % show the mapping again
                        DrawFormattedText(mainwin, ['Block No.', num2str(block)], 'center','center',white);
                        Screen('DrawText', mainwin, 'Target', tarpos(1)-20, tarpos(2)-70, white);
                        Screen('DrawText', mainwin, 'Distractor', dispos(1)-25, dispos(2)-70, white);
                        % target left
                        Screen('FillArc', mainwin, targetcolor(1,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(1), arcAngle);
                        Screen('FillArc', mainwin, targetcolor(2,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(2), arcAngle);
                        Screen('FillArc', mainwin, targetcolor(3,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(3), arcAngle);
                        Screen('FillArc', mainwin, targetcolor(4,:), CenterRectOnPoint(ballrect, tarpos(1),tarpos(2)), startAngle(4), arcAngle);
                        Screen('DrawLine', mainwin, black, tarpos(1) - radius, tarpos(2), tarpos(1) + radius, tarpos(2));
                        Screen('DrawLine', mainwin, black, tarpos(1), tarpos(2) - radius, tarpos(1), tarpos(2) + radius);
                        % distractor right
                        Screen('FillArc', mainwin, discolor(1,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(1), arcAngle);
                        Screen('FillArc', mainwin, discolor(2,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(2), arcAngle);
                        Screen('FillArc', mainwin, discolor(3,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(3), arcAngle);
                        Screen('FillArc', mainwin, discolor(4,:), CenterRectOnPoint(ballrect, dispos(1),dispos(2)), startAngle(4), arcAngle);
                        Screen('DrawLine', mainwin, black, dispos(1) - radius, dispos(2), dispos(1) + radius, dispos(2));
                        Screen('DrawLine', mainwin, black, dispos(1), dispos(2) - radius, dispos(1), dispos(2) + radius);
                        Screen('Flip',mainwin);
                        KbStrokeWait;
                        Screen('FillRect', mainwin, white, fixRect);
                        Screen('Flip', mainwin);
                    end
                end
            end
        end        
        
        keypressed =NaN;
        rt = NaN;
        if ~debug
            Eyelink('Message','trial_start');
        end
        
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
        
        if ~debug
            Eyelink('Message','trial_end');
        end
        
        respring = find(ismember(possiblekn,keypressed)) - 1;
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
        if trial == ntrialsperb
            WaitSecs(1);
        end
    end
end
session_end;

    function session_end
        if ~debug
            Eyelink('Message','session_end');
            Eyelink('Stoprecording');
            Eyelink('CloseFile');
            Eyelink('ReceiveFile');
        end
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
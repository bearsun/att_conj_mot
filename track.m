function track
% test trial by trial
% ntrials = 72;

preload = load('test.mat');
trials = preload.trial;


radius = 60;
framerate = 60;
screenrect = [1024, 0, 2048, 768];
fixrect = [0,0,8,8];
[ntrials, nframes, ~, nballs] = size(trials);
ntrialsperblock = 18;
preframes = 60 * 2; % 2s at the beginning of tracking/end of tracking
ntargets = 4;
nblinks = 6;
blinktime = .3;
prompttime = 2; %2s to response
pertarget = .5; % 50% target

% initialize everything
clc;
AssertOpenGL;
Priority(1);
sid = 0;
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
stired = [206 41 41];
stigreen = [28 139 28];
stiblue = [51 51 255];
stiyellow = [109 109 22];
colors = [stired;stigreen;stiblue;stiyellow];

colorsq = [ones(6,1),perms(2:4)]; % control red color
cindexes = 1:size(colorsq,1);

% for color from q1 to q4
startAngle = [0 90 180 270];
arcAngle = 90;
arcAnglefull = 360;
ballrect = [0,0,radius,radius];

%black = [0 0 0];
white = [255 255 255];
gray = [128 128 128];
black = [0 0 0];
fixcolor = white;
bgcolor = black;


kesc = KbName('Escape');
kn9 = KbName('9');
kn0 = KbName('0');
possiblekn = [kn9; kn0];

% Login screen
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
fprintf(outfile,'%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t \n', ...
    'subnum', 'subage', 'gender', 'group', 'session', 'block', 'trial', 'answer', 'keypressed', ...
    'ball1','ball2', 'ball3', 'ball4','ball5', 'ball6', 'ball7', 'ball8', 'targets','prompt','cor','rt');
% abbreviatedFilename=[subnum,'_',datestr(now,'mmdd')];


% build matrix for targets and distractors
% for target: the target for this subject will be mod(subnum-1,6) + 1
ctarget = mod(str2double(subnum)-1, size(colorsq, 1)) + 1;
cdistractors = (cindexes(~ismember(cindexes,ctarget)))';
factors = [cdistractors; ones(round(numel(cdistractors) * pertarget/(1-pertarget)),1) * ctarget];
alltarget = BalanceTrials(ntrials * ntargets, 1, factors);
alltarget = alltarget(1:ntrials * ntargets);
mattarget = reshape(alltarget,[],4);
alldis = BalanceTrials(ntrials * (nballs-ntargets), 1, cdistractors);
alldis = alldis(1:(ntrials * (nballs-ntargets)));
matdis = reshape(alldis,[],4);
matall = [mattarget,matdis];

% prompt mat to make sure distractors and targets are prompt 50/50
pmat = BalanceTrials(ntrials, 1, 1:nballs);

% initialize window
[mainwin, rect] = Screen('OpenWindow', sid, bgcolor, screenrect);

% background buffer
buffers = NaN(nframes,1);
t1 = GetSecs;
for f = 1:nframes
    [buffers(f),~] = Screen('OpenOffscreenWindow', mainwin);
end

[blinkbuffer, ~] = Screen('OpenOffscreenWindow', mainwin);
[pbuffer, ~] = Screen('OpenOffscreenWindow', mainwin);

disp(GetSecs - t1);

block = 1;
nr = 0;
for trial = 1:ntrials

%     if mod(trial,ntrialsperblock) == 1
%         block = num2str(ceil(trial/ntrialsperblock));
%         DrawFormattedText(mainwin, ['Block No.',block , ...
%             ',\n Please feel free to take a break.\n'], 'center', 'center', black);
%         Screen('Flip', mainwin);
%         KbStrokeWait;
%     end
    
    % draw everything on background buffers
    ballcolors = matall(trial,:);
    disp(ballcolors);
    t2 = GetSecs;
    for f = 1:nframes
        Screen('FillRect', buffers(f), bgcolor);
        Screen('FillRect', buffers(f), fixcolor, CenterRect(fixrect, rect));
        if f <= preframes
            for b = 1:nballs
                pos = trials(trial,f,1:2,b);
                bcolor = colorsq(ballcolors(b), :);
                fades = (colors(bcolor,:) - ones(4,1) * white) / preframes * (f-1) + ones(4,1) * white;
                fadeblack = (black-white) / preframes * (f-1) + white;
                Screen('FillArc', buffers(f), fades(1,:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(1), arcAngle);
                Screen('FillArc', buffers(f), fades(2,:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(2), arcAngle);
                Screen('FillArc', buffers(f), fades(3,:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(3), arcAngle);
                Screen('FillArc', buffers(f), fades(4,:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(4), arcAngle);
                Screen('FrameRect', buffers(f), fadeblack, CenterRectOnPoint(ballrect / 2, pos(1) -radius/2,pos(2)-radius/2));
                Screen('FrameRect', buffers(f), fadeblack, CenterRectOnPoint(ballrect / 2, pos(1) +radius/2,pos(2)+radius/2));
            end
            
        elseif f > (nframes-preframes)
            for b = 1:nballs
                pos = trials(trial,f,1:2,b);
                bcolor = colorsq(ballcolors(b), :);
                fades = (colors(bcolor,:) - ones(4,1) * white) / preframes * (nframes-f) + ones(4,1) * white;
                fadeblack = (black-white) / preframes * (nframes-f) + white;
                Screen('FillArc', buffers(f), fades(1,:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(1), arcAngle);
                Screen('FillArc', buffers(f), fades(2,:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(2), arcAngle);
                Screen('FillArc', buffers(f), fades(3,:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(3), arcAngle);
                Screen('FillArc', buffers(f), fades(4,:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(4), arcAngle);
                Screen('FrameRect', buffers(f), fadeblack, CenterRectOnPoint(ballrect / 2, pos(1) -radius/2,pos(2)-radius/2));
                Screen('FrameRect', buffers(f), fadeblack, CenterRectOnPoint(ballrect / 2, pos(1) +radius/2,pos(2)+radius/2));
            end
        else
            for b = 1:nballs
                pos = squeeze(trials(trial,f,1:2,b));
                bcolor = colorsq(ballcolors(b), :);
                Screen('FillArc', buffers(f), colors(bcolor(1),:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(1), arcAngle);
                Screen('FillArc', buffers(f), colors(bcolor(2),:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(2), arcAngle);
                Screen('FillArc', buffers(f), colors(bcolor(3),:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(3), arcAngle);
                Screen('FillArc', buffers(f), colors(bcolor(4),:), CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(4), arcAngle);
                Screen('FrameRect', buffers(f), black, CenterRectOnPoint(ballrect / 2, pos(1) -radius/2,pos(2)-radius/2));
                Screen('FrameRect', buffers(f), black, CenterRectOnPoint(ballrect / 2, pos(1) +radius/2,pos(2)+radius/2));
            end
        end
    end
    % blink buffer
    itarget = 1:ntargets;
    Screen('FillRect', blinkbuffer, bgcolor);
    Screen('FillRect', blinkbuffer, fixcolor, CenterRect(fixrect, rect));
    for b = 1:nballs
        pos = trials(trial,1,1:2,b);
        if ~ismember(b,itarget)
            Screen('FillArc', blinkbuffer, white, CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(1), arcAnglefull);            
        end
    end
    
    % prompt buffer
    ptarget = pmat(trial);
    disp('ptarget:');
    disp(ptarget);
    Screen('FillRect', pbuffer, bgcolor);
    Screen('FillRect', pbuffer, fixcolor, CenterRect(fixrect, rect));
    for b = 1:nballs
        pos = trials(trial,nframes,1:2,b);
        if b == ptarget
            Screen('FillArc', pbuffer, red, CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(1), arcAnglefull);
        else
            Screen('FillArc', pbuffer, white, CenterRectOnPoint(ballrect, pos(1),pos(2)), startAngle(1), arcAnglefull);
        end
    end
    
    disp(GetSecs - t2);
    % Wait to Start
    Screen('FillRect', mainwin, fixcolor, CenterRect(fixrect, rect));
    Screen('Flip', mainwin);
    KbStrokeWait;
    
    % blink the targets    
    for k = 1:nblinks
        if mod(k,2)
            Screen('DrawTexture', mainwin, buffers(1));
        else
            Screen('DrawTexture', mainwin, blinkbuffer);
        end
        Screen('Flip', mainwin);
        WaitSecs(blinktime);
    end
    
    % start tracking
    for f = 1:nframes
        Screen('DrawTexture', mainwin, buffers(f));
        Screen('Flip', mainwin);
    end

    % prompt for response
    Screen('DrawTexture', mainwin, pbuffer);
    Screen('Flip', mainwin);
    
    t3 = GetSecs;
    
    while 1
        [keyIsDown, secs, keyCode] = KbCheck;
        if secs - t3 > prompttime
            nr = 1;
            break;
        end
        FlushEvents('keyDown');
        if keyIsDown
            nKeys = sum(keyCode);
            if nKeys == 1
                if keyCode(kesc)
                    session_end;return
                elseif any(keyCode(possiblekn))
                    rt = secs-t3;
                    keypressed=find(keyCode);
                    break;
                end
            end
        end
    end
    
    targets = itarget(1)*1000+itarget(2)*100+itarget(3)*10 + itarget(4);
    answer = ismember(ptarget, itarget);
    
    if nr
        keypressed = NaN;
        rt = NaN;
        cor = 0;
        nr = 0;
    else
        resp = find(keypressed == [kn0,kn9]) - 1; % yes for 9 --resp = 1, no for 0, resp = 0
        cor = (answer == resp);
    end
    
    fprintf(outfile,'%s\t %s\t %s\t %s\t %s\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t \n', ...
    subnum, subage, gender, group, session, block, trial, answer, keypressed, ...
    trials(trial,1,3,1), trials(trial,1,3,2), trials(trial,1,3,3), trials(trial,1,3,4), trials(trial,1,3,5), trials(trial,1,3,6),...
    trials(trial,1,3,7), trials(trial,1,3,8), targets, ptarget,cor,rt);
    
% feedback
    if cor
        Screen('FillRect', mainwin, green, CenterRect(fixrect, rect));
    else
        Screen('FillRect', mainwin, red, CenterRect(fixrect, rect));
    end
    Screen('Flip', mainwin);
    if mod(trial,ntrialsperblock) == 0
        WaitSecs(1);
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

end
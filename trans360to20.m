% use interpolation to transform the 360 pix/s speed (6 pix/frame) to 60
% pix/s (1 pix/frame)

% upadte: transform to 20 pix/s, (.33 pix/frame) for staircase
% right now what we get is not every frame, but every 1/3 frame

framerate = 60;
preload = load('test_360_72.mat');
trials = preload.trial;
[ntrials, nframes, ~, nballs] = size(trials);

orig_speed = 360/framerate;
target_speed = 1/3;
tframes = (nframes-1) * orig_speed / target_speed + 1;% can't interpolate at the end

% set up frame sequence
f = 1:(orig_speed/target_speed):tframes;
tf = 1:tframes; 

newtrials = NaN(ntrials,tframes,2,nballs);
for j = 1:ntrials
    for i = 1:nballs
        vx = trials(j,:,1,i);
        vy = trials(j,:,2,i);
        newtrials(j,:,1,i) = interp1(f,vx,tf);
        newtrials(j,:,2,i) = interp1(f,vy,tf);
    end
end

save('test_i20.mat','newtrials');

%% little test for possible draws
possible_speed = 200:20:600;
nspeed = numel(possible_speed);
for i = 1:nspeed
    rate = possible_speed(i)/20;
    matpos = squeeze(newtrials(1,1:rate:(rate*432),1:2,:));
    disp(size(matpos,1));
end
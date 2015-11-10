function generatesequence(n)
% code to generate sequence of ball movements, and save all in a .mat file
% input: n: number of trials we want to generate
% we only need the x,y here

framerate = 60;
triallen = 12;
trialframe = framerate * triallen;

trial = NaN(n,trialframe,3,8); % trial X frame X (x,y,color) X ball


for i = 1:n
    b = 1;
    while b
        b = 0;
        temp = NaN(trialframe,3,8);
        balls = Balls();
        for s = 1:8
            balls.addBall();
        end
        
        for j = 1:trialframe
            temp(j,1,:) = balls.x;
            temp(j,2,:) = balls.y;
            temp(j,3,:) = balls.colorindex;
            jitter = mod(j, 20) == 0;
            b = balls.moveBall(jitter);
            if b
                break
            end
        end
    end
    trial(i,:,:,:) = temp;
    disp(i);
end

save(['newtest_', num2str(balls.speed),'.mat'], 'trial');

end
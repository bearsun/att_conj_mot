function attconj_mot
% function to run multiple objects tracking for the red/green/blue/yellow
% stimuli
% Liwei Sun, 10/8/15

% initialize everything
clc;
AssertOpenGL;
Priority(1);
sid = 0;
radius = 40;
speed = 500;
% colors
red = [255 0 0];
green = [0 255 0];
blue = [0 0 255];
yellow = [255 255 0];
colors = [red;green;blue;yellow];

% for color from q1 to q4
startAngle = [0 90 180 270];
arcAngle = 90;

black = BlackIndex(sid);
white = WhiteIndex(sid);
gray = GrayIndex(sid);

% initialize window
[mainwin, rect] = Screen('OpenWindow', sid, black,[800,0,1920,840]);
% initialize balls
balls = Balls(rect, radius, speed);
for i = 1:4
    balls.addBall();
end

for j = 1:240
    jitter = mod(j, 20) == 0;
    balls.moveBall(1,jitter);
    for i = 1:4
        bcolor = balls.colors(balls.colorindex(i), :);
        ballrect = [balls.x(i) - balls.radius(i), balls.y(i) - balls.radius(i), ...
            balls.x(i) + balls.radius(i), balls.y(i) + balls.radius(i)];
        Screen('FillArc', mainwin, colors(bcolor(1),:), ballrect, startAngle(1), arcAngle);
        Screen('FillArc', mainwin, colors(bcolor(2),:), ballrect, startAngle(2), arcAngle);
        Screen('FillArc', mainwin, colors(bcolor(3),:), ballrect, startAngle(3), arcAngle);
        Screen('FillArc', mainwin, colors(bcolor(4),:), ballrect, startAngle(4), arcAngle);
    end
    Screen('Flip', mainwin);
    balls.x
    balls.y
    WaitSecs(.05);
end

% speed problem, too slow



end
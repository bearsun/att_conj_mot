function stisample


startAngle = [0 90 180 270];
arcAngle = 90;
ballrect = [0,0,50,50];
rect = [0,0,1024,768];
center = [rect(3)/2 rect(4)/2];
pos = NaN(4,6,2);
pos(1,:,2) = center(2) - 180;
pos(2,:,2) = center(2) - 60;
pos(3,:,2) = center(2) + 60;
pos(4,:,2) = center(2) + 180;
pos(:,1,1) = center(1) - 300;
pos(:,2,1) = center(1) - 180;
pos(:,3,1) = center(1) - 60;
pos(:,4,1) = center(1) + 60;
pos(:,5,1) = center(1) + 180;
pos(:,6,1) = center(1) + 300;


colorsq = perms(1:4);

red = [255 0 0];
green = [0 255 0];
blue = [0 0 255];
yellow = [255 255 0];
colors = [red;green;blue;yellow];

% stired = [206 41 41];
% stigreen = [28 139 28];
% stiblue = [51 51 255];
% stiyellow = [109 109 22];
% colors = [stired;stigreen;stiblue;stiyellow];

mainwin=Screen('OpenWindow', 0, [128,128,128], rect);

for i = 1:4
    for j = 1:6
        icolor = (i-1) * 6 + j;
        color = colors(colorsq(icolor,:),:);
        Screen('FillArc', mainwin, color(1,:), CenterRectOnPoint(ballrect, pos(i,j,1),pos(i,j,2)), startAngle(1), arcAngle);
        Screen('FillArc', mainwin, color(2,:), CenterRectOnPoint(ballrect, pos(i,j,1),pos(i,j,2)), startAngle(2), arcAngle);
        Screen('FillArc', mainwin, color(3,:), CenterRectOnPoint(ballrect, pos(i,j,1),pos(i,j,2)), startAngle(3), arcAngle);
        Screen('FillArc', mainwin, color(4,:), CenterRectOnPoint(ballrect, pos(i,j,1),pos(i,j,2)), startAngle(4), arcAngle);
    end
end


Screen('Flip',mainwin);

KbStrokeWait;
sca;

end
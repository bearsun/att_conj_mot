classdef Balls<handle
%----------------------
%Multiple Objects Tracking Paradigm
%Updated by Liwei, 10/8/15
%
%--------------------------------------------------------------------------
%Collision Ball Libraries
%Version 1.00
%Created by Stepen
%Created 20 March 2013
%Last modified 20 May 2013
%--------------------------------------------------------------------------
%Constructor Format:
%- Balls()
%  creates an empty Collision Ball object.
%- Balls(x,y,u,v)
%  creates a Collision Ball where x, y, u, and v respectively are column
%  array with same row length defining balls position and velocity.
%- Balls(x,y,u,v,m,r,c)
%  creates a Collision Ball where x, y, u, v, m, r, and c respectively are
%  column array (except for c is 3column array) with same row length
%  defining balls position, velocity, mass, radius, and color.
%Public Non-static Method:
%- addBall(x,y,u,v,m,r,c)
%  add a ball to Collision Ball object.
%- addRandomBall(x,y,u,v,m,r,c)
%  add a random ball to Collision Ball object.
%- removeBall(ballID)
%  remove selected ball from Collision Ball object.
%- isOccupied(x,y,r)
%  check whether a ball at x and y position with radius of r can be added
%  to Collision Ball ojbect without conflict.
%- moveBall(dt)
%  move all balls in Collision Ball object for given time interval.
%- draw()
%  plot all balls in Collision Ball object at current time.
%- play(dt)
%  move and animate all balls in Collision Ball object using given time
%  interval as animation refresh rate.
%Public Static Method:
%- isOutBound(x,y,radius)
%  check a ball at x and y position with radius of r is within Collision
%  Ball object's containment space.
%--------------------------------------------------------------------------

%CodeStart-----------------------------------------------------------------
%Declaring object properties
    properties(SetAccess=protected)
        n_ball
        colorindex % index refer to the row in colors
        x
        y
        u
        v
        radius
        ANIMATIONSTAT=false;
        dradius
        dspeed
        XMIN
        XMAX
        YMIN
        YMAX
    end
%Declaring constant
    properties(Constant=true)
        % constant radius
        dcolor = [0,0,255]; %in case present in matlab
        % use color RGBY, represented by 1:4
        % each col corresponding to a quandrant
        % so we should have 24 different combination of colors for balls
        colors = perms(1:4);
        ncolors = size(Balls.colors,1);
        UMIN=-50;
        UMAX=50;
        VMIN=-50;
        VMAX=50;
        additionalgap = 100; % 20 pixels, minimum distance between balls,
        % not including radius
        angleturn = pi / 6;
        jitterfreq = 5; % add random jitter at 12 Hz (every 5 flips on a
                        % 60 Hz Screen
        jitterspeed = 200; % the speed to add
        jitterangles = ((-1:.25:1)* pi / 9)';
    end
%Declaring constructor
    methods
        function this=Balls(rect,radius,speed)
            rng('shuffle');
            %Initiating field
            this.n_ball=0;
            this.dradius = radius;
            this.dspeed = speed;
            this.XMIN = rect(1);
            this.YMIN = rect(2);
            this.XMAX = rect(3);
            this.YMAX = rect(4);
            this.colorindex=zeros(0,1);
            this.radius = zeros(0,1);
            this.x=zeros(0,1);
            this.y=zeros(0,1);
            this.u=zeros(0,1);
            this.v=zeros(0,1);
        end
    end
%Declaring public method
    methods
        %Declaring method to add a ball
        function addBall(this,colorindex,x,y,u,v)
            %Checking input arguments
            switch nargin
                case 1
                    this.addRandomBall();
                    return
                case 2
                    this.addRandomBall(colorindex);
                    return;
                case 6
                    Balls.checkfivevarargins(x,y,u,v,colorindex);
                otherwise
                    error('Unexpected format of input argument!');
            end
            %Checking for validity
            if this.isOccupied(x,y,this.dradius)
                error('New ball is conflicting with the existing balls!');
            end
            if this.isOutBound(x,y,this.dradius)
                error('New ball is out of bounds!');
            end
            %Adding ball
            this.n_ball=this.n_ball+1;
            this.radius=[this.radius;this.dradius];
            this.colorindex=[this.colorindex;colorindex];
            this.x=[this.x;x];
            this.y=[this.y;y];
            % normalize speed to dspeed
            [u,v] = Balls.normspeed(u,v,this.dspeed);
            this.u=[this.u;u];
            this.v=[this.v;v];
%             %Updating drawing plot (if drawing already exist)
%             mainfig=Balls.getfigurehandle();
%             if ~isempty(mainfig)
%                 rectangle('Parent',Balls.getaxeshandle(),...
%                           'FaceColor',Balls.dcolor/255,...
%                           'Curvature',[1,1],...
%                           'Position',[x-Balls.dradius,y-Balls.dradius,...
%                                       2*Balls.dradius,2*Balls.dradius]);
%             end
        end
        %Declaring method to add a random ball
        function addRandomBall(this,cr)
            %Initiating variable for while loop
            canBeAdded=false;
            %Generating random ball until it is valid
            while ~canBeAdded
                switch nargin
                    case 1
                        %Generating random position
                        [xr,yr,ur,vr,cr]=this.generateball();
                    case 2
                        [xr,yr,ur,vr,cr]=this.generateball(cr);
                    otherwise
                        error('Unexpected format of input argument!');
                end
                %Checking random ball validity
                canBeAdded=(~this.isOccupied(xr,yr,this.dradius))&&...
                           (~this.isOutBound(xr,yr,this.dradius));
            end
            %Adding random ball
            this.addBall(cr,xr,yr,ur,vr);
        end
        %Declaring method to remove a ball
        function removeBall(this,ballID)
            %Checking input value
            Balls.checksinglevarargin(ballID);
            if ballID>this.n_ball
                error('Ball ID should be less that number of balls!')
            end
            %Deleting ball
            this.radius(ballID)=[];
            this.colorindex(ballID,:)=[];
            this.x(ballID)=[];
            this.y(ballID)=[];
            this.u(ballID)=[];
            this.v(ballID)=[];
            this.n_ball=this.n_ball-1;
            %Updating ball drawing (if drawing already exist)
            mainfig=Balls.getfigurehandle();
            if ~isempty(mainfig)
                rectlist=findobj(mainfig,'Type','rect');
                delete(rectlist(this.n_ball+2-ballID))
            end
        end
        %Declaring method to check whether a position is available
        function stat=isOccupied(this,x,y,radius)
            %Initiating output variable
            stat=false;
            %Checking space for each ball
            for i=1:this.n_ball
                S=norm([this.x(i)-x,this.y(i)-y]);
                if S<(this.radius(i) + radius + Balls.additionalgap)
                    stat=true;
                    return
                end
            end
        end
        %Declaring function to move the balls
        function moveBall(this,dt, JITTER)
            % jitter the speed
            if JITTER
                jitterdirection(this);
            end
            %Predicting ball position without considering collision
            [xf,yf]=predictposition(this,dt);
            %Finding collision
            stat=Balls.findcollision(xf,yf,this.radius);
            %while ~isempty(stat)
                %Correcting the speed of colliding balls
                for i=1:size(stat,1)
                    ID1=stat(i,1);
                    ID2=stat(i,2);
                    [this.u(ID1),this.v(ID1),...
                     this.u(ID2),this.v(ID2)]=Balls.collide(this.x(ID1),...
                                                            this.y(ID1),...
                                                            this.u(ID1),...
                                                            this.v(ID1),...
                                                            this.x(ID2),...
                                                            this.y(ID2),...
                                                            this.u(ID2),...
                                                            this.v(ID2));
                end
                %Finding out-of-bount balls
                hstat=(xf<this.XMIN+this.radius)|...
                      (xf>this.XMAX-this.radius);
                %Change direction of u
                this.u(hstat)=-this.u(hstat);
                vstat=(yf<this.YMIN+this.radius)|...
                      (yf>this.YMAX-this.radius);
                %Change direction of v
                this.v(vstat)=-this.v(vstat);
                %Limiting maximum speed
                this.u(this.u<Balls.UMIN)=Balls.UMIN;
                this.u(this.u>Balls.UMAX)=Balls.UMAX;
                this.v(this.v<Balls.VMIN)=Balls.VMIN;
                this.v(this.v>Balls.VMAX)=Balls.VMAX;
                %Recalculating ball position with updated velocity
                [xf,yf]=predictposition(this,dt);
                %Rechecking collision
                %stat=Balls.findcollision(xf,yf,this.radius);
                %Updating ball position
                this.x=xf;
                this.y=yf;
        end
    end
%Declaring private method
    methods(Access=protected)
        %Declaring function to move ball by neglecting collision
        function [x,y]=predictposition(this,dt)
            x=this.x+(this.u*dt)/2;
            y=this.y+(this.v*dt)/2;
        end
        
        %Declaring function to jitter the direction of ball movement
        function jitterdirection(this)
            % current speed angle
            spangle = atan2(this.u, this.v);
            % randomly draw a jitterangle (relative to current angle)
            addangle = this.jitterangles(randi(numel(this.jitterangles),size(spangle)));
            % angle to add speed
            newangle = spangle + addangle;
            % add speed
            newu = this.u + Balls.jitterspeed * sin(newangle);
            newv = this.v + Balls.jitterspeed * cos(newangle);
            % normalize speed
            [this.u,this.v] = Balls.normspeed(newu,newv,this.u,this.v);
        end
        %Declaring function to generate random ball
        function [xr,yr,ur,vr,cr]=generateball(this,cr)
            if nargin < 2
                cr = randi(Balls.ncolors);
            end
            rr = this.dradius;
            xr=this.XMIN+rr+...
                (rand*(this.XMAX-this.XMIN-(2*rr)));
            yr=this.YMIN+rr+...
                (rand*(this.YMAX-this.XMIN)-(2*rr));
            ur=Balls.UMIN+(rand*(Balls.UMAX-Balls.UMIN));
            vr=Balls.VMIN+(rand*(Balls.VMAX-Balls.VMIN));
        end
            %Declaring method to check whether a ball is out of bound
        function stat=isOutBound(this,x,y,radius)
            %Initiating output variable
            stat=false;
            %Checking space for ball position
            if (x<this.XMIN+radius)||(x>this.XMAX-radius)||...
               (y<this.YMIN+radius)||(y>this.YMAX-radius)
                stat=true;
                return;
            end
        end
    end
%Declaring static private methods
    methods(Access=protected,...
            Static=true)
        %Declaring function to check input argument for constructor
        function checksinglevarargin(var1)
            %Checking varargin array size
            if numel(var1)~=1
                error('Input number of balls must be a scalar!');
            end
            %Checking varargin data type
            if (var1<=0)||(mod(var1,1)~=0)
                error('Input number of balls must be a positive integer!');
            end
        end
        function checkfourvarargins(var1,var2,var3,var4)
            %Checking varargin array size
            if (numel(var1)~=1)||(numel(var2)~=1)||...
               (numel(var3)~=1)||(numel(var4)~=1)
                error('Input x, y, u, and v must be a scalar!');
            end
            %Checking varargin data type
            if (~isreal(var1))||(~isreal(var2))||...
               (~isreal(var3))||(~isreal(var4))
                error('Input x, y, u, and v must be real numbers!');
            end
        end
        function checkfivevarargins(var1,var2,var3,var4,var5)
            %Checking varargin for x,y,u,v
            Balls.checkfourvarargins(var1,var2,var3,var4);
            %Checking varargin colorindex
            if ~ismember(var5,1:Balls.ncolors);
                error(['Input colorindex must be a positive integer',...
                       ' between 1 and 24!']);
            end
        end

        %Declaring function to find colliding balls
        function stat=findcollision(x,y,r)
            %Preallocating array for output variable
            stat=zeros(0,2);
            %Finding collision
            for i=1:numel(x)-1
                if isempty(find(stat(:,2)==i, 1))
                    for j=i+1:numel(x)
                        S=norm([x(i)-x(j),y(i)-y(j)]);
                        if S<(r(i)+r(j) + Balls.additionalgap)
                            stat=[stat;[i,j]]; %#ok<AGROW>
                            %break
                        end
                    end
                end
            end
        end
        %Declaring function to resolve 2D collision
        function [uf1,vf1,uf2,vf2]=collide(x1,y1,u1,v1,x2,y2,u2,v2)
            %Finding normal angle between two balls
            theta=atan2(y2-y1,x2-x1);
            
            %Transforming balls velocity to normal coordinate
            VN1=(u1*cos(theta))+(v1*sin(theta));
            VT1=(-u1*sin(theta))+(v1*cos(theta));
            VN2=(u2*cos(theta))+(v2*sin(theta));
            VT2=(-u2*sin(theta))+(v2*cos(theta));
            % turn the direction by angleturn degree
            VN1_F = abs(VT1) * tan(Balls.angleturn) * (-VN1)/abs(VN1);
            VN2_F = abs(VT2) * tan(Balls.angleturn) * (-VN2)/abs(VN2);
% %             %Resolving colllision for normal axis
% %             VN1_F=((VN1*(m1-m2))+(2*m2*VN2))/(m1+m2);
% %             VN2_F=((VN2*(m2-m1))+(2*m1*VN1))/(m1+m2);
%             % adding a repellent speed vector proposional to the distance
%             VN1_F = VN1 - VN1 / norm([y2-y1,x2-x1]) * Balls.repellc;
%             VN2_F = VN2 - VN2 / norm([y2-y1,x2-x1]) * Balls.repellc;
            %Retransforming balls velocity to original coordinate
            uf1=(VN1_F*cos(theta))-(VT1*sin(theta));
            vf1=(VN1_F*sin(theta))+(VT1*cos(theta));
            uf2=(VN2_F*cos(theta))-(VT2*sin(theta));
            vf2=(VN2_F*sin(theta))+(VT2*cos(theta));
            % normalize the speed to the original speed
            [uf1,vf1] = Balls.normspeed(uf1,vf1,u1,v1);
            [uf2,vf2] = Balls.normspeed(uf2,vf2,u2,v2);
        end
        
        %Declaring function that normalize speed to the original speed
        function [u,v] = normspeed(uf,vf,uo,vo)
            switch nargin
                case 4
            ratio = sqrt((uo.^2 + vo.^2) ./ (uf.^2 + vf.^2));

                case 3
                    dspeed = uo;
                    ratio = dspeed / (uf.^2 + vf.^2);
                otherwise
                    error('Unexpected format of input argument!');
            end
            u = uf .* ratio;
            v = vf .* ratio;
        end
    end
%CodeEnd-------------------------------------------------------------------
    
end
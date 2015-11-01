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
        ANIMATIONSTAT=false;
    end
    %Declaring constant
    properties(Constant=true)
        dtime = 1/60; %speed of updating screen
        radius = 40; % constant radius
        speed = 400; % constant speed per frame
        % use color RGBY, represented by 1:4
        % each col corresponding to a quandrant
        % so we should have 24 different combination of colors for ball
        colors = perms(1:4);
        ncolors = size(Balls.colors,1);
        additionalgap = 40; % 140 pixels, minimum distance between balls,
        % not including radius
        softcap = Balls.radius * 2 + Balls.additionalgap;
        hardcap = Balls.radius * 2 + Balls.additionalgap / 6;
        absolutecap = Balls.radius * 2;
        angleturn = pi / 12;
        jitterfreq = 100; % add random jitter at 3 Hz (every 10 flips on a
        % 30 Hz Screen
        %        jitterspeed = 100; % the speed to add
        njitter = 2;
        jitterangles = ((-1:.25:1)* pi / 12)';
        XMIN = 0;
        YMIN = 0;
        XMAX = 1024;
        YMAX = 768;
    end
    %Declaring constructor
    methods
        function this=Balls()
            rng('shuffle');
            %Initiating field
            this.n_ball=0;
            this.colorindex=zeros(0,1);
            this.x=zeros(0,1);
            this.y=zeros(0,1);
            this.u=zeros(0,1);
            this.v=zeros(0,1);
        end
    end
    %Declaring public method
    methods
        %Declaring method to add a ball
        function addBall(this,colorindex,x,y,theta)
            %Checking input arguments
            switch nargin
                case 1
                    this.addRandomBall();
                    return
                case 2
                    this.addRandomBall(colorindex);
                    return;
                case 5
                    % do nothing
                otherwise
                    error('Unexpected format of input argument!');
            end
            %Checking for validity
            if this.isOccupied(x,y)
                error('New ball is conflicting with the existing balls!');
            end
            if this.isOutBound(x,y)
                error('New ball is out of bounds!');
            end
            %Adding ball
            this.n_ball=this.n_ball+1;
            this.colorindex=[this.colorindex;colorindex];
            this.x=[this.x;x];
            this.y=[this.y;y];
            [uf,vf] = Balls.speed2uv(Balls.speed, theta);
            this.u=[this.u;uf];
            this.v=[this.v;vf];
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
                        [xr,yr,tr,cr]=this.generateball();
                    case 2
                        [xr,yr,tr,cr]=this.generateball(cr);
                    otherwise
                        error('Unexpected format of input argument!');
                end
                %Checking random ball validity
                canBeAdded=(~this.isOccupied(xr,yr))&&...
                    (~this.isOutBound(xr,yr));
            end
            %Adding random ball
            this.addBall(cr,xr,yr,tr);
        end
        %Declaring method to remove a ball
        function removeBall(this,ballID)
            %Checking input value
            if ballID>this.n_ball
                error('Ball ID should be less that number of balls!')
            end
            %Deleting ball
            this.colorindex(ballID)=[];
            this.x(ballID)=[];
            this.y(ballID)=[];
            this.u(ballID)=[];
            this.v(ballID)=[];
            this.n_ball=this.n_ball-1;
        end
        %Declaring method to check whether a position is available
        function stat=isOccupied(this,x,y)
            %Initiating output variable
            stat=false;
            %Checking space for each ball
            for i=1:this.n_ball
                S=norm([this.x(i)-x,this.y(i)-y]);
                if S<(Balls.radius * 2 + Balls.additionalgap)
                    stat=true;
                    return
                end
            end
        end
        %Declaring function to move the balls
        function b = moveBall(this, JITTER)
            dt = Balls.dtime;
            % jitter the speed
            if JITTER
                jitterdirection(this);
            end

            %Predicting ball position without considering collision
            [xf,yf]=predictposition(this,dt);
            %Finding collision
            stat=Balls.findcollision(xf,yf);
            stat=sort(stat,2);
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
            hstat=(xf<Balls.XMIN+this.radius)|...
                (xf>Balls.XMAX-this.radius);
            this.u(hstat)=-this.u(hstat);
            vstat=(yf<Balls.YMIN+this.radius)|...
                (yf>Balls.YMAX-this.radius);
            this.v(vstat)=-this.v(vstat);
            %Recalculating ball position with updated velocity
            [xf,yf]=predictposition(this,dt);
            %Rechecking collision
            %stat=Balls.findcollision(xf,yf,this.radius);
            %Updating ball position
            this.x=xf;
            this.y=yf;
            d = pdist([this.x,this.y]);
            b = any(d < Balls.absolutecap);
        end
    end
    %Declaring private method
    methods(Access=protected)
        %Declaring function to move ball by neglecting collision
        function [x,y]=predictposition(this,dt)
            x=this.x+(this.u*dt);
            y=this.y+(this.v*dt);
        end
        
        %Declaring function to jitter the direction of ball movement
        function jitterdirection(this)
            % current speed angle
            spangle = atan2(this.u, this.v);
            % draw 2 balls to jitter
            kjitter = randi(size(spangle,1),[Balls.njitter,1]);
            % randomly draw a jitterangle (relative to current angle)
            addangle = Balls.jitterangles(randi(numel(Balls.jitterangles),[Balls.njitter,1]));
            % angle to add speed
            theta = spangle(kjitter) + addangle;
%             % add speed
%             newu = this.u + Balls.jitterspeed .* sin(newangle);
%             newv = this.v + Balls.jitterspeed .* cos(newangle);
%             % change angle
%             [~, theta] = Balls.uv2speed(newu, newv);
            [this.u(kjitter),this.v(kjitter)] = Balls.speed2uv(Balls.speed,theta);
        end
        %Declaring function to generate random ball
        function [xr,yr,theta,cr]=generateball(this,cr)
            if nargin < 2
                cr = randi(Balls.ncolors);
            end
            rr = Balls.radius;
            xr=this.XMIN+rr+...
                (rand*(this.XMAX-this.XMIN-(2*rr)));
            yr=this.YMIN+rr+...
                (rand*(this.YMAX-this.XMIN)-(2*rr));
            theta = rand * pi * 2 - pi;
        end

    end
    %Declaring static private methods
    methods(Access=protected,...
            Static=true)
        
        %Declaring function to find colliding balls
        function stat=findcollision(x,y)
            %Preallocating array for output variable
            stat=zeros(0,2);
            %Finding collision
            for i=1:numel(x)-1
                if isempty(find(stat(:,2)==i, 1))
                    for j=i+1:numel(x)
                        S=norm([x(i)-x(j),y(i)-y(j)]);
                        if S< Balls.softcap
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
                            
            if (VN2-VN1)>0
                [~,t1] = Balls.uv2speed(u1,v1);
                [~,t2] = Balls.uv2speed(u2,v2);
                [uf1,vf1] = Balls.speed2uv(Balls.speed,t1);
                [uf2,vf2] = Balls.speed2uv(Balls.speed,t2);
                return
            end
            
            dis = norm([y2-y1,x2-x1]);
            
            if dis < Balls.hardcap
                
                % elastic collision
                VN1_F= VN2;
                VN2_F= VN1;
                %Retransforming balls velocity to original coordinate
                uf1=(VN1_F*cos(theta))-(VT1*sin(theta));
                vf1=(VN1_F*sin(theta))+(VT1*cos(theta));
                uf2=(VN2_F*cos(theta))-(VT2*sin(theta));
                vf2=(VN2_F*sin(theta))+(VT2*cos(theta));
                
            else
                %                 d = dis / Balls.softcap;

                [~,t1] = Balls.uv2speed(u1, v1);
                [~,t2] = Balls.uv2speed(u2, v2);
                newt1 = t1 + Balls.angleturn;
                newt2 = t2 - Balls.angleturn;
                [uf1,vf1] = Balls.speed2uv(Balls.speed,newt1);
                [uf2,vf2] = Balls.speed2uv(Balls.speed,newt2);
            end
% 
%             d = norm([x1-x2,y1-y2]);
%             dt = Balls.dtime;
%             %Transforming balls velocity to normal coordinate
%             VN1=(u1*cos(theta))+(v1*sin(theta));
%             VN2=(u2*cos(theta))+(v2*sin(theta));
%             
%             a=cos(Balls.angleturn);
%             %Resolving colllision for normal axis
%             VN1_F= VN1*(1 - a);
%             VN2_F= VN2*(1 - a);
%             
%             
%             %scale to orig speed
%             VT1 = Balls.calvt(VN1_F);
%             VT2 = -Balls.calvt(VN2_F);
%             
%             %Retransforming balls velocity to original coordinate
%             uf1=(VN1_F*cos(theta))-(VT1*sin(theta));
%             vf1=(VN1_F*sin(theta))+(VT1*cos(theta));
%             uf2=(VN2_F*cos(theta))-(VT2*sin(theta));
%             vf2=(VN2_F*sin(theta))+(VT2*cos(theta));

            
            
        end
        
        %Declaring method to check whether a ball is out of bound
        function stat=isOutBound(x,y)
            %Initiating output variable
            stat=false;
            %Checking space for ball position
            if (x<Balls.XMIN+Balls.radius)||(x>Balls.XMAX-Balls.radius)||...
                    (y<Balls.YMIN+Balls.radius)||(y>Balls.YMAX-Balls.radius)
                stat=true;
                return;
            end
        end
        %Declaring function that transform speed to u,v
        function [u,v] = speed2uv(speed, theta)
            u = speed .* cos(theta);
            v = speed .* sin(theta);
        end
        
        function [speed,theta] = uv2speed(u, v)
            speed = sqrt(u.^2 + v.^2);
            theta = atan2(v,u);
        end
        
        function vt = calvt(vn)
            vt = sqrt(Balls.speed^2 - vn^2);
            if ~isreal(vt)
                vt = 0;
                disp('what');
            end
        end
    end
    %CodeEnd-------------------------------------------------------------------
    
end
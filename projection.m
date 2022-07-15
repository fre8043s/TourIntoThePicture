function points2d = projection(points, pos, ang)
    % campos [x, y, z]
    % ang [x, y]
    f = 1000;
    pitch = ang(1) * pi/180;
    yaw = ang(2) * pi/180;
    
    s = size(points, 1);

    A = [-1, 0, 0, pos(1);
        0,  1,  0, -pos(2);
        0,  0, -1, pos(3)];
        
    Rotx = [1, 0, 0;
            0, cos(pitch), -sin(pitch);
            0, sin(pitch),  cos(pitch)];
    
    Roty = [cos(yaw), 0, sin(yaw);
            0, 1, 0;
            -sin(yaw), 0, cos(yaw)];
        
    Invx = [-1 0;
            0  1];
        
    % Transform to camera coordinate system
    world = points(:,1:3);
    colors = points(:,4:6);
    K = Rotx * Roty * A;
    coords = (K * [world';ones(1, s)])';

    % Remove points behind camera
    for i = 1:s
        if coords(i, 3) < 0
            coords(i, :) = [nan, nan, nan];
            colors(i, :) = [nan, nan, nan];
        end
    end
    
    % Project on 2d plane
    transvec = zeros(s, 2);
    for i = 1:s
        transvec(i,:) = f/coords(i, 3) * coords(i, 1:2);
    end
        
    transpoints = (Invx * transvec')'; 

    points2d = [transpoints, colors];
        
end
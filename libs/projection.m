function points2d = projection(points, pos, ang)
    %  Project a 3D world on to a 2D image for a certain viewing point
    %
    % :param points: 3D points in M x 6 Matrix [x, y, z, r,  g, b]
    % :param pos: Camera Position Vector [x, y, z]
    % :param ang:  Camera Angle Vector pitch, yaw [rotx, roty] (right hand rule for angle sign)
    %
    % :return points2d: 2D Points Vector [x', y', r, g, b]

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
    world = double(points(:,1:3));
    colors = double(points(:,4:6));
    K = Rotx * Roty * A;
    coords = (K * [world';ones(1, s)])';

    % Remove points behind image plane
    i = 1; 
    while i <= s
        if coords(i, 3) < f
            coords(i, :) = [];
            colors(i, :) = [];
            i = i - 1;
            s = s - 1;
        end
        i = i + 1;
    end
    
    % Project on 2d plane
    transvec = zeros(s, 2);
    for i = 1:s
        transvec(i,:) = f/coords(i, 3) * coords(i, 1:2);
    end
        
    transpoints = (Invx * transvec')'; 

    points2d = double([transpoints, colors]);
        
end

function img = fillimage(points)
    % Create an Image Matrix from a list (matrix) of points with
    % corresponding colors
    % 
    % :param points: M x 5 [x, y, r, g, b]
    %
    % :return img: Image matrix size_y x size_x x 3 [r, g, b]
    
    s = size(points, 1);

    points(:, 1:2) = -points(:, 1:2);
    
    sizex = max(points(:,1)) - min(points(:, 1)) + 1;
    sizey = max(points(:,2)) - min(points(:, 2)) + 1;
    
    sizex = ceil(sizex);
    sizey = ceil(sizey);
    
    % shift points by negative range
    points(:, 1) = points(:, 1) - min(points(:, 1));
    points(:, 2) = points(:, 2) - min(points(:, 2));
    

    g = NaN(sizey, sizex, 3);
    
    for i = 1:s
        g(int32(points(i, 2))+1, int32(points(i, 1))+1, :) = points(i, 3:5);
    end
    img = g;
end
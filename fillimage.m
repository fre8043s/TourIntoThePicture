function img = fillimage(points)
    s = size(points, 1);

    points(:, 1:2) = -points(:, 1:2);
    
    sizex = max(points(:,1));
    sizey = max(points(:,2));
    
    
    sizex = ceil(sizex);
    sizey = ceil(sizey);

    g = NaN(sizey+1, sizex+1, 3);
    
    for i = 1:s
        g(int32(points(i, 2))+1, int32(points(i, 1))+1, :) = points(i, 3:5);
    end
    img = g;
end
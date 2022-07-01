image = imread('TourIntoThePicture/CV-Challenge-22-Datensatz/oil-painting.png');
% imshow(image);
[sizey, sizex, three] = size(image)


x = 21;
y = 21;
rgb = image(x, y, :);
inner_rectangle = [10, 10, sizex-10, sizey-10];
vp = [ceil(sizex/2), ceil(sizey/2)];


my3d = get_world_from_original([x, y], "Rear", vp, inner_rectangle);

function wp = get_world_from_original(pt, area, vp, inner)
    % get 3D point from 2d point
    %
    % :param pt: 1x2 input point [x, y]
    % :param area: string from ("Floor", ...)
    % :param vp: 1x2 vanish point [x, y]
    % :param inner: 1x4 values inner rectangle [x_min, y_min, x_max, y_max]
    % :returns: 1x3
    f= 1;
    in_lft = inner(1);
    in_bot = inner(2);
    in_rgt = inner(3);
    in_top = inner(4);
%     vp_x = vp(1);
%     vp_y = vp(2);
    
    d = vp(2) / (vp(2) - in_bot);
    
    
    
    if area == "Floor"
    end
    
    if area == "Ceiling"
        
    end
    
    if area == "Rear"
        wpx = (f+d) / f * (pt(1) - in_lft);
        wpy = (f+d) / f * (pt(2) - in_bot);
        wpz = 0;
        
    end
    
    if area == "Left"
    end
    
    if area == "Right"
        
    end
    wp = [wpx, wpy, wpz];
end

    
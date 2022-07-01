image = imread('CV-Challenge-22-Datensatz/oil-painting.png');
% imshow(image);
[sizey, sizex, three] = size(image)


x = 210;
y = 210;
rgb = image(x, y, :);
inner_rectangle = [100, 100, sizex-100, sizey-100];
vp = [ceil(sizex/2), ceil(sizey/2)];


my3d = get_world_from_original([sizex-100, sizey-100], "Rear", vp, inner_rectangle, [sizex, sizey]);
%my3d = get_world_from_original([100, 100], "Floor", vp, inner_rectangle, [sizex, sizey])
%my3d = get_world_from_original([700, sizey-80], "Ceiling", vp, inner_rectangle, [sizex, sizey])


function wp = get_world_from_original(pt, area, vp, inner, dim)
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
    
    d_btm = (vp(2) * f / (vp(2) - in_bot)) - f
    d_top = ((dim(2) - vp(2)) * f/ (in_top - vp(2))) - f
    d_lft = (vp(1) * f / (vp(1) - in_lft)) - f
    d_rgt = ((dim(1) - vp(1)) * f/ (in_rgt - vp(1))) - f
    
    
    
    if area == "Floor"
        deltalft = pt(1) - vp(1) 
        deltabtm = vp(2) - pt(2)
        wpz = d_btm - (vp(2) / deltabtm * f -f)
        dinv = f + d_btm - wpz 
        wpx = vp(1) + deltalft / f * dinv 
        wpy = 0   
    end
    
    if area == "Ceiling"
        deltalft = pt(1) - vp(1)
        wpy = in_top
        deltatop = pt(2) - vp(2)
        wpz = d_top - ((dim(2) - vp(2))/deltatop * f - f)
        dinv = f + d_top - wpz
        wpx = vp(1) + deltalft / f * dinv
        
        
    end
    
    if area == "Rear"
        wpx = (f+d_lft) / f * (pt(1) - in_lft);
        wpy = (f+d_btm) / f * (pt(2) - in_bot);
        wpz = 0;
        
    end
    
    if area == "Left"
    end
    
    if area == "Right"
        
    end
    wp = [wpx, wpy, wpz];
end

    
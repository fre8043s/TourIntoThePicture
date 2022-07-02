% Testing the 3D transformation:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% image = imread('CV-Challenge-22-Datensatz/oil-painting.png');
% % imshow(image);
% [size_y, size_x, channels] = size(image);
% 
% 
% x = 210;
% y = 210;
% rgb = image(x, y, :);
% inner_rectangle = [100, 100, size_x-100, size_y-100];
% vp = [ceil(size_x/2), ceil(size_y/2)];
% 
% my3d = get_world_from_original([size_x-100, size_y-100], "Rear", vp, inner_rectangle, [size_x, size_y])
% my3d = get_world_from_original([100, 100], "Floor", vp, inner_rectangle, [size_x, size_y])
% my3d = get_world_from_original([700, size_y-80], "Ceiling", vp, inner_rectangle, [size_x, size_y])
% my3d = get_world_from_original([100, 100], "Left", vp, inner_rectangle, [size_x, size_y])
% my3d = get_world_from_original([size_x-100, size_y-100], "Right", vp, inner_rectangle, [size_x, size_y])
%%% End Tests %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    in_btm = inner(2);
    in_rgt = inner(3);
    in_top = inner(4);
%     vp_x = vp(1);
%     vp_y = vp(2);
    
    d_btm = (vp(2) * f / (vp(2) - in_btm)) - f;
    d_top = ((dim(2) - vp(2)) * f/ (in_top - vp(2))) - f;
    d_lft = (vp(1) * f / (vp(1) - in_lft)) - f;
    d_rgt = ((dim(1) - vp(1)) * f/ (in_rgt - vp(1))) - f;
%     d_room = max(max(d_btm, d_top), max(d_lft, d_rgt));
    
    
    if area == "Floor"
        wpy = 0;
        delta_lft = pt(1) - vp(1);
        delta_btm = vp(2) - pt(2);
        wpz = d_btm - (vp(2) / delta_btm * f -f);
        dinv = f + d_btm - wpz;
        wpx = vp(1) + delta_lft / f * dinv;
    end
    
    if area == "Ceiling"
        wpy = dim(2);
        delta_lft = pt(1) - vp(1);
        delta_top = pt(2) - vp(2);
        wpz = d_top - ((dim(2) - vp(2))/delta_top * f - f);
        dinv = f + d_top - wpz;
        wpx = vp(1) + delta_lft / f * dinv;
        
        
    end
    
    if area == "Rear"
        wpx = (f+d_lft) / f * (pt(1) - in_lft); % d_room here?
        wpy = (f+d_btm) / f * (pt(2) - in_btm); % d_room here?
        wpz = 0;
        
    end
    
    if area == "Left"
        wpx = 0;
        delta_lft = vp(1) - pt(1);
        delta_btm = pt(2) - vp(2);
        wpz = d_lft - (vp(1)/delta_lft * f - f);
        dinv = f + d_btm - wpz;
        wpy = vp(2) + delta_btm / f * dinv;
        
    end
    
    if area == "Right"
        wpx = dim(1);
        delta_rgt = pt(1) - vp(1);
        delta_btm = pt(2) - vp(2);
        wpz = d_rgt - ((dim(1) - vp(1)) / delta_rgt * f - f);
        dinv = f + d_btm - wpz;
        wpy = vp(2) + delta_btm / f * dinv;
    end
    wp = [wpx, wpy, wpz];
end

    
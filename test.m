image = imread('..\\CV-Challenge-22-Datensatz\\oil-painting.png');
imshow(image);
hold on
% specify the outer rectangle
oup_left = [0, 0];
odown_left = [0, size(image,1)];
oup_right = [size(image,2), 0];
odown_right = [size(image,2), size(image,1)];
corners = [oup_left; oup_right; odown_right; odown_left];
rectangle('Position', [0,0,size(image,2),size(image,1)],'LineWidth',1,'EdgeColor','blue');


% specify the vanish point and draw the radial lines
vanish_point = specify_vanish_point(image, corners);

% specify the outer rectangle
%p = specify_inner_rectangle(image, corners);


%% specify the vanishing point and inner Rectangle
function vanish_point = specify_vanish_point(image, corners)
    [x,y] = getpts;
    vanish_point = [round(x), round(y)];
    plot(vanish_point(1),vanish_point(2),'*','color','blue');
    
    % draw the main radial lines
    for i = 1:length(corners)
        radial_line = [vanish_point;corners(i,:)];
        plot(radial_line(:,1),radial_line(:,2),'LineWidth',1,'color','blue');
    end
    % draw the other radial lines
    outer_fixies = [];
    radial_size = 10;
    for k = 1:radial_size
        for j = 1:length(corners)
            outer_fixies = [outer_fixies; [round(k*corners(j,1)/radial_size), corners(j,2)]];
            outer_fixies = [outer_fixies; [corners(j,1), round(k*corners(j,2)/radial_size)]];
        end
    end
    outer_fixies = unique(outer_fixies,'rows');
    for l = 1:length(outer_fixies)
        radial_line = [vanish_point;outer_fixies(l,:)];
        plot(radial_line(:,1),radial_line(:,2),'LineWidth',0.5,'color','blue');
    end
end
function p = specify_inner_rectangle(image, corners)
    p = getrect;
    p = round(p);
    rectangle('Position', p, 'EdgeColor', 'blue');
    
    % specify the init vanish point with inner rect and outer rect
    p_cell = num2cell(p);
    [x,y,w,h] = deal(p_cell{:});
    innen_corners = [[x,y];[x+w,y];[x+w,y+h];[x,y+h]];
    for i = 1:length(corners)
        outer_corner = corners(i,:);
        inner_corner = innen_corners(i,:);
        k = (outer_corner(2)-inner_corner(2))/(outer_corner(1)-inner_corner(1));
        b = outer_corner(2)-k*outer_corner(1);
        x = 0:1:size(image,2);
        plot(x,k*x+b,'color','blue');
    end
end

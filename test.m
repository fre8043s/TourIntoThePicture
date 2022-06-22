image = imread('..\\\CV-Challenge-22-Datensatz\oil-painting.png');
imshow(image);
hold on
% specify the outer rectangle
oup_left = [0, 0];
odown_left = [0, size(image,1)];
oup_right = [size(image,2), 0];
odown_right = [size(image,2), size(image,1)];
corners = [oup_left; oup_right; odown_right; odown_left];
rectangle('Position', [0,0,size(image,2),size(image,1)],'LineWidth',2,'EdgeColor','blue');

% specify the vanish point and draw the radial lines
vanish_point = specify_vanish_point(image, corners);
% specify the outer rectangle
p = specify_inner_rectangle(image);

%% specify the vanishing point and inner Rectangle
function vanish_point = specify_vanish_point(image, corners)
    [x,y] = getpts;
    vanish_point = [round(x), round(y)];
    plot(vanish_point(1),vanish_point(2),'*','color','blue');
    % draw the radial lines
    for i = 1:length(corners)
        radial_line = [vanish_point;corners(i,:)];
        plot(radial_line(:,1),radial_line(:,2),'LineWidth',2,'color','blue');
    end
end
function p = specify_inner_rectangle(image)
    p = getrect;
    p = round(p);
    rectangle('Position', p, 'EdgeColor', 'blue');
end

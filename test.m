image = imread('..\\..\\CV-Challenge-22-Datensatz\oil-painting.png');
imshow(image);
hold on
% specify the outer rectangle
oup_left = [0, 0];
odown_left = [0, size(image,1)];
oup_right = [size(image,2), 0];
odown_right = [size(image,2), size(image,1)];
plot([oup_left(1),odown_left(1),odown_right(1),oup_right(1),oup_left(1)],[oup_left(2),odown_left(2),odown_right(2),oup_right(2),oup_left(2)],'LineWidth',2,'color','blue')

% specify the vanish point and draw the radial lines
vanish_point = specify_vanish_point();
% specify the outer rectangle
p = specify_inner_rectangle();

%% specify the vanishing point and inner Rectangle
function vanish_point = specify_vanish_point()
    [x,y] = getpts;
    vanish_point = [round(x), round(y)];
    plot(vanish_point(1),vanish_point(2),'*','color','blue');
    % draw the radial lines
    theta = 0:0.1:2*pi;
    rho = 1;
    polarplot(theta, rho)
end
function p = specify_inner_rectangle()
    p = getrect;
    p = round(p);
    rectangle('Position', p, 'EdgeColor', 'blue');
end

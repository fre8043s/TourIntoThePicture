var;
imageSize = [1152, 829];
pos = [imageSize(1), imageSize(2), 2000];
ang = [0, 0];



projected = projection(Table, pos, ang);

% scatter(projected(:,1),projected(:,2),20,projected(:,3:5)./255,'fill');
% axis equal;
% title('Rendered perspective');

% subplot(1,2,1);
% scatter3(Table(:,1),Table(:,2),Table(:,3),20,Table(:,4:6)/255,'fill');
% axis equal;
% title('Original Points');
% 
% subplot(1,2,2);
% scatter(projected(:,1),projected(:,2),40,projected(:,3:5)/255,'fill');
% axis equal;
% % camproj('perspective');
% title('Points projected with camera model');

ret = fillimage(projected);


% ret = imread('./lowres.png');


% ret(11:20, 11:20, :) = NaN(10, 10, 3);
% imshow(ret);
mask = isnan(ret(:, :, 1));

% mask = zeros(144, 192);
% mask(11:20, 11:20) = ones(10, 10);

ret_r = ret(:, :, 1);
ret_g = ret(:, :, 2);
ret_b = ret(:, :, 3);
ret_r = regionfill(ret_r, mask);
ret_g = regionfill(ret_g, mask);
ret_b = regionfill(ret_b, mask);


recombinedimg(:, :, 1) = uint8(ret_r);
recombinedimg(:, :, 2) = uint8(ret_g);
recombinedimg(:, :, 3) = uint8(ret_b);

% imtool(recombinedimg) 
imshow(recombinedimg);
% imwrite(ret, "oil_top_right.png");
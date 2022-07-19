classdef main < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        Toolbar                     matlab.ui.container.Toolbar
        ToggleTool                  matlab.ui.container.toolbar.ToggleTool
        GridLayout                  matlab.ui.container.GridLayout
        ButtonGroup                 matlab.ui.container.ButtonGroup
        loadingIcon                 matlab.ui.control.Image
        loadingLabel                matlab.ui.control.Label
        RenderImageButton           matlab.ui.control.Button
        YawSlider                   matlab.ui.control.Slider
        YawSliderLabel              matlab.ui.control.Label
        PitchSlider                 matlab.ui.control.Slider
        PitchSliderLabel            matlab.ui.control.Label
        CamZSlider                  matlab.ui.control.Slider
        CamZSliderLabel             matlab.ui.control.Label
        CamXSlider                  matlab.ui.control.Slider
        CamXSliderLabel             matlab.ui.control.Label
        CamYSlider                  matlab.ui.control.Slider
        CamYSliderLabel             matlab.ui.control.Label
%         CreateForegroundMaskButton  matlab.ui.control.Button
        CreateGridModelButton       matlab.ui.control.Button
        OpenFileButton              matlab.ui.control.Button
        UIAxes                      matlab.ui.control.UIAxes
    end

    properties (Access = private)
        % flags
        drawVP_flag     % check wether VP is defined and drawn
        drawRW_flag     % check wether inner Rectangle(Rear Window) is drawn
        drawRL_flag     % check wether Radial Lines are drawn
        drawPO_flag     % check wether Polygons are drawn
        drawFO_flag     % check wether Foreground Objects are drawn
        draw_moveable_flag % check wether a part of Radial Lines, the selectable RL is set to a point
        
        stop_motion_VP_RL
        space
        
        InputImage      % documentation of the Image
        
        % spider mesh
        VanishPoint     % Vanishing Point size 2x1
        MovingPoint     % moving Radial Point size 2x1
        OuterRect       % specify the four corners of outer rectangle with direction upleft-upright-downright-downleft size 2x4
        OuterFixies     
        InnerRect       % specify the four corners of Rear Window with direction upleft-upright-downright-downleft size 2x4
        InnerCorrespond % correspond points of InnerRect on the OuterRect based on the VP size 2x4
        OuterCorrespond % correspond points of InnerRect on the imagined edge of OuterRect based on the VP size 2x4
        Verticies       % 2d Camera Coordinates Pixels size 2x12 
        Coordination    % 3d World  Coordinates Pixels size 3x12 
        
        % distinguish Foreground and Background
        ForegroundObj 
        
        % variables 3D reconstruction
        depth_estimation = 1000
        verticies3Dvalues=[]
        cell_with3Dpoints       % cell is the size of the chosen image (every pixel has its own 3D point)
        matrix_with3Dpoints     % matrix with 3D coordinates
        points3D_and_colormap   % XYZ RGB size M x 6   
        CameraPoint = [1,1]
        flag3DModel=false
    end
    
    properties (Access = public)
        draw_outer_rect     % control the drawing of outer rect
        draw_inner_rect     % * of inner rect
        draw_vp             % * of Vanish Point
        draw_cam
        draw_radial         % * of Radial Lines
        draw_polygons       % * of 2d Polygons of each side of the rebuilt 3d. 1x5 Vector with direction of leftwall, ceiling, rightwall, floor and rearwall
        draw_vertices       % * of notation of 12 Verticies
        draw_moveable_radial% control the selectable point of a radial line

        radial_size         % define the density of the radial lines
    end
    
    % specify VanishPoint, InnerRect, OuterRect and RadialLines (function)
    methods (Access = private)
        
        % check if mouse is within axes
        function [new_point, isInAxes] = check_mouse_within_axes(app)
            isInAxes = true;
            cp = app.UIAxes.CurrentPoint(1,1:2);
            if cp(1) < 0 % x-axis
                cp(1) = 0;
                isInAxes = false;
            elseif cp(1) > size(app.InputImage,2)
                cp(1) = size(app.InputImage,2);
                isInAxes = false;
            end
            if cp(2) < 0 % y-axis
                cp(2) = 0;
                isInAxes = false;
            elseif cp(2) > size(app.InputImage,1)
                cp(2) = size(app.InputImage,1);
                isInAxes = false;
            end
            new_point = cp;
        end
        
        % initialize RearWindow and VP
        function initialize_RearWindow_and_VanishPoint(app)
            ylim = size(app.InputImage,1);
            xlim = size(app.InputImage,2);
            
            app.InnerRect = [[xlim/4;ylim/4],[3*xlim/4;ylim/4],[3*xlim/4;3*ylim/4],[xlim/4;3*ylim/4]];
            app.VanishPoint = [xlim/2;ylim/2];
            app.draw_inner_rect = drawrectangle(app.UIAxes,'Position',[xlim/4,ylim/4,xlim/2,ylim/2]);
            NameArray = {'Label', 'LabelAlpha', 'LabelTextColor', 'FaceAlpha', 'FaceSelectable'};
            ValueArray = {'IR', 0, 'white', 0, false};
            set(app.draw_inner_rect, NameArray, ValueArray);

            app.draw_vp = drawpoint(app.UIAxes, 'Position', app.VanishPoint');
            NameArray = {'Label', 'LabelAlpha', 'LabelTextColor'};
            ValueArray = {'VP', 0, 'white'};
            set(app.draw_vp, NameArray, ValueArray);
            
            app.drawVP_flag = true;
            app.drawRW_flag = true;
        end

        % draw the initial outer rectangle
        function specify_OuterRectangle(app)
            app.OuterRect = [[0,0]',[size(app.InputImage,2),0]',[size(app.InputImage,2),size(app.InputImage,1)]',[0,size(app.InputImage,1)]'];
            app.draw_outer_rect = drawrectangle(app.UIAxes, 'Position', [0,0,size(app.InputImage,2),size(app.InputImage,1)]);
            NameArray = {'Label', 'LabelAlpha', 'LabelTextColor', 'FaceAlpha', 'InteractionsAllowed'};
            ValueArray = {'OuterRect', 0, 'white', 0, 'none',};
            set(app.draw_outer_rect, NameArray, ValueArray);
            % preparation of radial lines based on outer fixies
            n = 1;
            for i = 1:app.radial_size
                for j = 1:length(app.OuterRect)
                    app.OuterFixies(:, n) = [round(i*app.OuterRect(1,j)/app.radial_size); app.OuterRect(2,j)];
                    app.OuterFixies(:, n+1) = [app.OuterRect(1,j); round(i*app.OuterRect(2,j)/app.radial_size)];
                    n = n + 2;
                end
            end
            app.OuterFixies = unique(app.OuterFixies', 'rows')';
        end
        
        % draw the initial VP and RL
        function specify_VanishPoint(app)
            % check wether the VP is drawn & if it is already drawn, get its current position 
            % if button is selected, set it to interactable
            if app.drawVP_flag
                app.VanishPoint = app.draw_vp.Position';
                app.update_RadialLines();
                return;
            end
        end

        % draw the inner rectangle
        function specify_RearWindow(app)
            if app.drawRW_flag
                inner_rect_pos = app.draw_inner_rect.Position;
                app.InnerRect = [[inner_rect_pos(1);inner_rect_pos(2)],...
                                 [inner_rect_pos(1)+inner_rect_pos(3);inner_rect_pos(2)],...
                                 [inner_rect_pos(1)+inner_rect_pos(3);inner_rect_pos(2)+inner_rect_pos(4)],...
                                 [inner_rect_pos(1);inner_rect_pos(2)+inner_rect_pos(4)]];
                app.update_RadialLines();
                return;
            end
        end
        
        % draw radial lines
        function specify_RadialLines(app)
            if ~app.drawVP_flag || ~app.drawRW_flag
                return;
            end
            if app.drawRL_flag
                % change VP position based on trajectory of L2
                app.MovingPoint = app.draw_moveable_radial.Position';
                
                fixie_inner_3 = app.InnerRect(:,3);
                fixie_inner_4 = app.InnerRect(:,4);
                fixie_corres_3 = app.InnerCorrespond(:,3);
                fixie_line_k = (fixie_inner_3(2)-fixie_corres_3(2))/(fixie_inner_3(1)-fixie_corres_3(1));
                fixie_line_b = fixie_inner_3(2)-fixie_line_k*fixie_inner_3(1);
                
                new_line_k = (fixie_inner_4(2)-app.MovingPoint(2))/(fixie_inner_4(1)-app.MovingPoint(1));
                new_line_b = fixie_inner_4(2) - new_line_k*fixie_inner_4(1);

                app.VanishPoint = [(new_line_b-fixie_line_b)/(-new_line_k+fixie_line_k); new_line_k*(new_line_b-fixie_line_b)/(-new_line_k+fixie_line_k)+new_line_b];
                set(app.draw_vp,'Position',app.VanishPoint')
                app.update_RadialLines();
            end
        end
        
        % update the position of radial lines and redraw
        function update_RadialLines(app)
            if ~app.drawVP_flag || ~app.drawRW_flag
                return;
            end
            app.clear_drawing('RL');

            % plot the radial lines
            for l = 1:length(app.OuterFixies)
                radial_line = [app.VanishPoint app.OuterFixies(:,l)]';
                app.draw_radial(l) = drawline(app.UIAxes, 'Position', radial_line, 'InteractionsAllowed', 'none', 'Linewidth', 0.5);
            end
            for m = 1:length(app.InnerRect)
                % calculate the corresponding points based on current VP and InnerRect
                [app.InnerCorrespond(:,m), app.OuterCorrespond(:,m)] = app.correspond_point_to_outer_rect(app.VanishPoint, app.InnerRect(:,m));
                radial_line = [app.VanishPoint app.InnerCorrespond(:,m)]';
                if m ~= 4
                    app.draw_radial(l+m) = drawline(app.UIAxes, 'Position', radial_line, 'InteractionsAllowed', 'none', 'Linewidth', 2);
                else
                    app.MovingPoint = app.InnerCorrespond(:,4)';
                    if app.draw_moveable_flag
                        set(app.draw_moveable_radial,'Position',app.MovingPoint);
                    else
                        app.draw_moveable_radial = drawpoint(app.UIAxes, 'Position', app.MovingPoint, 'Label', 'Moveable', 'LabelAlpha', 0, 'LabelTextColor', 'white');
                        app.draw_moveable_flag = true;
                    end
                    app.draw_radial(l+m) = drawline(app.UIAxes, 'Position', [app.VanishPoint app.draw_moveable_radial.Position']', 'InteractionsAllowed', 'none', 'Linewidth', 2);
                end
            end
            app.drawRL_flag = true;
        end

        % update camera position
%         function update_CameraPoint(app)
%             cam = [app.CamXSlider.Value / 100 * size(app.InputImage, 2), app.CamYSlider.Value / 100 * size(app.InputImage, 1), max(app.points3D_and_colormap(:, 3)), 0, 0, 0];
%             ang = [app.PitchSlider.Value, app.YawSlider.Value];
%             orig = [0.5 * size(app.InputImage, 2), 
%                    0.5 * size(app.InputImage, 1),
%                    2.5 * max(app.points3D_and_colormap(:, 3))]; %TODO +1000?
% %             temp = projection(cam, orig, ang);
% %             app.CameraPoint  = ([-1, 0; 0, size(app.InputImage, 1) - 1] * temp(1:2)');
% %             set(app.draw_cam,'Position',app.CameraPoint')
%         end
              
        % specify the imagined edges of outer rectangle and return the five polygons
        function specify_Polygons(app)
            if app.drawPO_flag
                return;
            end
            app.clear_drawing('PO');

            % connection of four next points to bild the polygon
            last_inner = app.InnerCorrespond(:,4); 
            last_outer = app.OuterCorrespond(:,4);
            last_innerRect = app.InnerRect(:,4);
            for i = 1:length(app.InnerRect)
                this_inner = app.InnerCorrespond(:,i);
                this_outer = app.OuterCorrespond(:,i);
                this_innerRect = app.InnerRect(:,i);
                if this_inner(1) == last_outer(1) || this_inner(2) == last_outer(2)
                    connection_pair = [last_outer this_inner];
                    app.draw_polygons(i) = drawpolygon(app.UIAxes,'Position',[last_innerRect connection_pair this_innerRect]','InteractionsAllowed','none','Color',[0 0.4470 0.7410]);
                elseif this_inner(1) == last_inner(1) || this_inner(2) == last_inner(2)
                    connection_pair = [last_inner this_inner];
                    app.draw_polygons(i) = drawpolygon(app.UIAxes,'Position',[last_innerRect connection_pair this_innerRect]','InteractionsAllowed','none','Color',[0.8500 0.3250 0.0980]);
                elseif this_outer(1) == last_inner(1) || this_outer(2) == last_inner(2)
                    connection_pair = [last_inner this_outer];
                    app.draw_polygons(i) = drawpolygon(app.UIAxes,'Position',[last_innerRect connection_pair this_innerRect]','InteractionsAllowed','none','Color',[0.9290 0.6940 0.1250]);
                elseif this_outer(1) == last_outer(1) || this_outer(2) == last_outer(2)
                    connection_pair = [last_outer this_outer];
                    app.draw_polygons(i) = drawpolygon(app.UIAxes,'Position',[last_innerRect connection_pair this_innerRect]','InteractionsAllowed','none','Color',[0.4940 0.1840 0.5560]);
                end
                app.Verticies(:,(i-1)*3+1:i*3)= [last_innerRect connection_pair];
                last_inner = this_inner;
                last_outer = this_outer;
                last_innerRect = this_innerRect;
            end
            app.draw_polygons(end) = drawpolygon(app.UIAxes,'Position',app.InnerRect','InteractionsAllowed','none','Color',[0.6350 0.0780 0.1840]);
            for i = 1:length(app.Verticies)
                app.draw_vertices(i) = drawpoint(app.UIAxes,'Position',app.Verticies(:,i)','InteractionsAllowed','none','Label',string(i));
            end
            % customize the window of drawn polygons
            app.drawPO_flag = true;
        end
        
        % calculate 3D vertiices
        function calculate3Dverticies(app)
            % first step: set point 1 to [0 0 0] which is the origin of the world coordinate frame
            % -->the numbering of the
            % verticies in app.Verticies in this code is not the same as in the paper
            % the numbering of app.verticies3D is the same as in the paper though 
            app.verticies3Dvalues=[0 0 0];
            % calc pixel distance between point 12 and 11 (points
            % where radial lines cross with bottom line) which is the width
            % of 3D scene in pixels
            width_of_scene=app.calculate_distance(app.Verticies(:,11),app.Verticies(:,12)); 
            % set the x value of point 10 and lower
            % right point of inner rect to width of scene
            app.verticies3Dvalues=[app.verticies3Dvalues; [width_of_scene 0 0]];
            % use pre defined depth information to 
            app.verticies3Dvalues=[app.verticies3Dvalues; [0 0 app.depth_estimation]];
            app.verticies3Dvalues=[app.verticies3Dvalues; [width_of_scene 0 app.depth_estimation]];
            % calculate depht information for points 5 and 6 throught
            % ratios between 1 and 3 + 2 and 4:
            % point 5
            dist13=app.calculate_distance(app.Verticies(:,1),app.Verticies(:,12));
            dist15=app.calculate_distance(app.Verticies(:,1),app.Verticies(:,2));
            depth_of_5=app.depth_estimation*(dist15/dist13);
            app.verticies3Dvalues=[app.verticies3Dvalues; [0 0 depth_of_5]];
            % point 6
            dist24=app.calculate_distance(app.Verticies(:,10),app.Verticies(:,11));
            dist26=app.calculate_distance(app.Verticies(:,10),app.Verticies(:,9));
            depth_of_6=app.depth_estimation*(dist26/dist24);
            app.verticies3Dvalues=[app.verticies3Dvalues; [width_of_scene 0 depth_of_6]];
            % now we have to estimate the High H of the scene
            % therefor we take points 3 and 4. From there we go straigth up
            % and calculate the crossing point with upper left and right
            % radial line --> the difference is the height in pixel 
            % we take both values and take the average as the heigth
            vector_8_minus_7=app.Verticies(:,8)-app.Verticies(:,7);
            vector_11_minus_7=app.Verticies(:,11)-app.Verticies(:,7);
            solution_2_by_2_system_of_equations1=[[0;1] vector_8_minus_7]\vector_11_minus_7;
            height1=solution_2_by_2_system_of_equations1(1);
            % second height value: 
            vector_3_minus_4=app.Verticies(:,3)-app.Verticies(:,4);
            vector_12_minus_4=app.Verticies(:,12)-app.Verticies(:,4);
            solution_2_by_2_system_of_equations2=[[0;1] vector_3_minus_4]\vector_12_minus_4;
            height2=solution_2_by_2_system_of_equations2(1);
            H=(height1+height2)/2;
            % assign 3D points 7 and 8 
            app.verticies3Dvalues=[app.verticies3Dvalues; [0 H 0]];
            app.verticies3Dvalues=[app.verticies3Dvalues; [width_of_scene H 0]];
            % depth values of points 9 10 11 and 12 can also be calculated
            % with similar and the existing system of equations
            vector_5_minus_4=app.Verticies(:,5)-app.Verticies(:,4);
            vector_12_minus_4=app.Verticies(:,12)-app.Verticies(:,4);
            solution_2_by_2_system_of_equations3=[[0;1] vector_5_minus_4]\vector_12_minus_4;   
            % point 9:
            app.verticies3Dvalues=[app.verticies3Dvalues; [0 H ((1/solution_2_by_2_system_of_equations3(2))*app.depth_estimation)]];
            % same goes for point 10:
            vector_6_minus_7=app.Verticies(:,6)-app.Verticies(:,7);
            vector_11_minus_7=app.Verticies(:,11)-app.Verticies(:,7);
            solution_2_by_2_system_of_equations4=[[0;1] vector_6_minus_7]\vector_11_minus_7;
            % point 10:
            app.verticies3Dvalues=[app.verticies3Dvalues; [width_of_scene H ((1/solution_2_by_2_system_of_equations4(2))*app.depth_estimation)]];
            % depth of points 11 and 12 is already given in
            % solution_2_by_2_system_of_equations1 and
            % solution_2_by_2_system_of_equations2
            % point 11 
            app.verticies3Dvalues=[app.verticies3Dvalues; [0 H ((1/solution_2_by_2_system_of_equations2(2))*app.depth_estimation)]];
            % point 12
            app.verticies3Dvalues=[app.verticies3Dvalues; [width_of_scene H ((1/solution_2_by_2_system_of_equations1(2))*app.depth_estimation)]]; 
        end
        
        % create 3D polygons
        function [innerrect,bottom,top ,left, right]=create3Dpolygons(app)
            innerrect= [app.verticies3Dvalues(1,:); app.verticies3Dvalues(2,:);app.verticies3Dvalues(8,:); app.verticies3Dvalues(7,:); app.verticies3Dvalues(1,:)];
            bottom= [app.verticies3Dvalues(1,:); app.verticies3Dvalues(2,:);app.verticies3Dvalues(4,:); app.verticies3Dvalues(3,:); app.verticies3Dvalues(1,:)];
            top= [app.verticies3Dvalues(7,:); app.verticies3Dvalues(8,:);app.verticies3Dvalues(10,:); app.verticies3Dvalues(9,:); app.verticies3Dvalues(7,:)];
            left= [app.verticies3Dvalues(1,:); app.verticies3Dvalues(5,:);app.verticies3Dvalues(11,:); app.verticies3Dvalues(7,:); app.verticies3Dvalues(1,:)];
            right= [app.verticies3Dvalues(2,:); app.verticies3Dvalues(6,:);app.verticies3Dvalues(12,:); app.verticies3Dvalues(8,:); app.verticies3Dvalues(2,:)];
        end
        
        % calculate 3D points 
        function calculate3DPoints(app)
             %assign a 3D point to every pixel of the image:
             [y_max,x_max,~]=size(app.InputImage);
             for y=1:y_max
                 for x=1:x_max
                     if app.checkifPoint_is_inside_innerrect(x,y)
                         point3D=app.calc3Dpoint_inside_innerrect(x,y);
                         app.matrix_with3Dpoints(y, x, :)=point3D;
                     elseif app.checkifPoint_is_inside_bottom(x,y)
                         point3D=app.calc3Dpoint_inside_bottom(x,y);
                         app.matrix_with3Dpoints(y, x, :)=point3D;
                     elseif app.checkifPoint_is_inside_top(x,y)
                         point3D=app.calc3Dpoint_inside_top(x,y);   
                         app.matrix_with3Dpoints(y, x, :)=point3D;
                     elseif app.checkifPoint_is_inside_left(x,y)
                         point3D=app.calc3Dpoint_inside_left(x,y); 
                         app.matrix_with3Dpoints(y, x, :)=point3D;
                     elseif app.checkifPoint_is_inside_right(x,y)
                          point3D=app.calc3Dpoint_inside_rigth(x,y); 
                          app.matrix_with3Dpoints(y, x, :)=point3D;
                     else 
                         disp("point not in polygons")
                     end 
                 end
             end
         end
         
         % calculate 3D points of inner rectangle 
         function point3D=calc3Dpoint_inside_innerrect(app,x,y)
                % z coordinate is always 0
                % x is ratio  compared to 1 and 10 
                width_of_scene=app.verticies3Dvalues(4,1);
                width_of_point= width_of_scene*(abs(x-app.Verticies(1,1))/abs(app.Verticies(1,1)-app.Verticies(1,10)));
                % y is ratio  compared to 1 and 4
                heigth_of_scene=app.verticies3Dvalues(7,2);
                heigth_of_point= heigth_of_scene*(abs(y-app.Verticies(2,1))/abs(app.Verticies(2,1)-app.Verticies(2,4)));
                point3D=[width_of_point heigth_of_point 0];
         end
         
         % calculate 3D points of floor 
         function point3D=calc3Dpoint_inside_bottom(app,x,y)
                %y coordinate is always 0
                width_of_scene=app.verticies3Dvalues(4,1);
                depth_of_scene=app.depth_estimation;
                %calculate x and z (width)
                Verticies_10_minus_11=app.Verticies(:,10)-app.Verticies(:,11);
                Verticies_10_minus_point=[app.Verticies(1,10)-x; app.Verticies(2,10)-y];
                first_solution=[[1;0] Verticies_10_minus_11]\Verticies_10_minus_point;
                
                Verticies_1_minus_12=app.Verticies(:,1)-app.Verticies(:,12);
                Verticies_1_minus_point=[app.Verticies(1,1)-x; app.Verticies(2,1)-y];
                second_solution=[[-1;0] Verticies_1_minus_12]\Verticies_1_minus_point;
                
                width_of_point=width_of_scene*(second_solution(1)/(first_solution(1)+second_solution(1)));
                %average of both depth calculations
                depth_of_point=depth_of_scene*(first_solution(2)*(second_solution(1)/(first_solution(1)+second_solution(1)))+second_solution(2)*(first_solution(1)/(first_solution(1)+second_solution(1))));
                
                point3D=[width_of_point 0 depth_of_point];
         end
         
         % calculate 3D points of ceiling 
         function point3D=calc3Dpoint_inside_top(app,x,y)
                %y coordinate is always height
                width_of_scene=app.verticies3Dvalues(4,1);
                height_of_scene=app.verticies3Dvalues(8,2);
                depth_of_scene=app.verticies3Dvalues(9,3);
                %calculate x and z (width)
                Verticies_7_minus_6=app.Verticies(:,7)-app.Verticies(:,6);
                Verticies_7_minus_point=[app.Verticies(1,7)-x; app.Verticies(2,7)-y];
                first_solution=[[1;0] Verticies_7_minus_6]\Verticies_7_minus_point;
                
                Verticies_4_minus_5=app.Verticies(:,4)-app.Verticies(:,5);
                Verticies_4_minus_point=[app.Verticies(1,4)-x; app.Verticies(2,4)-y];
                second_solution=[[-1;0] Verticies_4_minus_5]\Verticies_4_minus_point;
                
                width_of_point=width_of_scene*(first_solution(1)/(first_solution(1)+second_solution(1)));
                %average of both depth calculations
                depth_of_point=depth_of_scene*(first_solution(2)*(second_solution(1)/(first_solution(1)+second_solution(1)))+second_solution(2)*(first_solution(1)/(first_solution(1)+second_solution(1))));
                
                point3D=[width_of_point height_of_scene depth_of_point];
         end
         
         % calculate 3D points of right wall
         function point3D=calc3Dpoint_inside_rigth(app,x,y)
                %x coordinate is always width
                width_of_scene=app.verticies3Dvalues(4,1);
                height_of_scene=app.verticies3Dvalues(8,2);
                depth_of_scene=app.verticies3Dvalues(6,3);
                %calculate y and z 
                Verticies_7_minus_8=app.Verticies(:,7)-app.Verticies(:,8);
                Verticies_7_minus_point=[app.Verticies(1,7)-x; app.Verticies(2,7)-y];
                first_solution=[[0;-1] Verticies_7_minus_8]\Verticies_7_minus_point;
                
                Verticies_10_minus_9=app.Verticies(:,10)-app.Verticies(:,9);
                Verticies_10_minus_point=[app.Verticies(1,10)-x; app.Verticies(2,10)-y];
                second_solution=[[0;1] Verticies_10_minus_9]\Verticies_10_minus_point;
                
                height_of_point=height_of_scene*(second_solution(1)/(first_solution(1)+second_solution(1)));
                %average of both depth calculations
                depth_of_point=depth_of_scene*(first_solution(2)*(second_solution(1)/(first_solution(1)+second_solution(1)))+second_solution(2)*(first_solution(1)/(first_solution(1)+second_solution(1))));
                
                point3D=[width_of_scene height_of_point depth_of_point];
         end
         
         % calculate 3D points of left wall
         function point3D=calc3Dpoint_inside_left(app,x,y)
               % x coordinate is always 0
                height_of_scene=app.verticies3Dvalues(8,2);
                depth_of_scene=app.verticies3Dvalues(5,3);
                % calculate y and z 
                Verticies_4_minus_3=app.Verticies(:,4)-app.Verticies(:,3);
                Verticies_4_minus_point=[app.Verticies(1,4)-x; app.Verticies(2,4)-y];
                first_solution=[[0;-1] Verticies_4_minus_3]\Verticies_4_minus_point;
                Verticies_1_minus_2=app.Verticies(:,1)-app.Verticies(:,2);
                Verticies_1_minus_point=[app.Verticies(1,1)-x; app.Verticies(2,1)-y];
                second_solution=[[0;1] Verticies_1_minus_2]\Verticies_1_minus_point;
                height_of_point=height_of_scene*(second_solution(1)/(first_solution(1)+second_solution(1)));
                % average of both depth calculations
                depth_of_point=depth_of_scene*(first_solution(2)*(second_solution(1)/(first_solution(1)+second_solution(1)))+second_solution(2)*(first_solution(1)/(first_solution(1)+second_solution(1))));
                point3D=[0 height_of_point depth_of_point];
         end
                     
         % check wether points is in the inner rectangle     
         function boolean=checkifPoint_is_inside_innerrect(app,x,y)
                x_values_innerrect_points=[app.Verticies(1,1) app.Verticies(1,10) app.Verticies(1,7) app.Verticies(1,4)];
                y_values_innerrect_points= [app.Verticies(2,1) app.Verticies(2,10) app.Verticies(2,7) app.Verticies(2,4)];
                boolean=inpolygon(x,y,x_values_innerrect_points,y_values_innerrect_points);
             end
             function boolean=checkifPoint_is_inside_bottom(app,x,y)
                x_values_innerrect_points=[app.Verticies(1,1) app.Verticies(1,12) app.Verticies(1,11) app.Verticies(1,10)];
                y_values_innerrect_points= [app.Verticies(2,1) app.Verticies(2,12) app.Verticies(2,11) app.Verticies(2,10)];
                boolean=inpolygon(x,y,x_values_innerrect_points,y_values_innerrect_points);
             end
             function boolean=checkifPoint_is_inside_top(app,x,y)
                x_values_innerrect_points=[app.Verticies(1,4) app.Verticies(1,7) app.Verticies(1,6) app.Verticies(1,5)];
                y_values_innerrect_points= [app.Verticies(2,4) app.Verticies(2,7) app.Verticies(2,6) app.Verticies(2,5)];
                boolean=inpolygon(x,y,x_values_innerrect_points,y_values_innerrect_points);
             end
             function boolean=checkifPoint_is_inside_left(app,x,y)
                x_values_innerrect_points=[app.Verticies(1,1) app.Verticies(1,4) app.Verticies(1,3) app.Verticies(1,2)];
                y_values_innerrect_points= [app.Verticies(2,1) app.Verticies(2,4) app.Verticies(2,3) app.Verticies(2,2)];
                boolean=inpolygon(x,y,x_values_innerrect_points,y_values_innerrect_points);
             end
             function boolean=checkifPoint_is_inside_right(app,x,y)
                x_values_innerrect_points=[app.Verticies(1,7) app.Verticies(1,10) app.Verticies(1,9) app.Verticies(1,8)];
                y_values_innerrect_points= [app.Verticies(2,7) app.Verticies(2,10) app.Verticies(2,9) app.Verticies(2,8)];
                boolean=inpolygon(x,y,x_values_innerrect_points,y_values_innerrect_points);
             end

        % specify foreground objects      
        function specify_ForegroundObjects(app)
            if app.drawFO_flag
                return;
            end
            poly = drawrectangle(app.UIAxes,'InteractionsAllowed','none');
            app.ForegroundObj{end+1} = poly;
            app.drawFO_flag = true;
        end
        
        % erase previous drawings 
        function clear_drawing(app, mode)
            switch mode
                case 'RL'
                    try
                        delete(app.draw_radial);
                        app.drawRL_flag = false;
                    catch
                    end
                case 'VP'
                    try 
                        delete(app.draw_vp);
                        app.drawVP_flag = false;
                    catch
                    end
                case 'RW'
                    try
                        delete(app.draw_inner_rect);
                        app.drawRW_flag = false;
                    catch
                    end
                case 'PO'
                    try
                        delete(app.draw_polygons);
                        app.drawPO_flag = false;
                    catch
                    end
                    try delete(app.draw_vertices);
                    catch
                    end
                case 'Moveable'
                    try
                        delete(app.draw_moveable_radial);
                        app.draw_moveable_flag = false;
                    catch
                    end
                case 'OR'
                    try 
                        delete(app.draw_outer_rect);
                    catch
                    end
                case 'all'
                    app.clear_drawing('RL');
                    app.clear_drawing('VP');
                    app.clear_drawing('RW');
                    app.clear_drawing('PO');
                    app.clear_drawing('Moveable');
                    app.clear_drawing('OR');
            end
        end
        
        % calculate the eucledean distance between two points
        function distance = calculate_distance(~, p1, p2)
            distance = norm(p2-p1);
        end

        % project the radial lines of inner rect on the outer rect
        function [CorrespondPoint, CorrespondPoint_Outer] = correspond_point_to_outer_rect(app, point, compared_point)
            if point(1) == compared_point(1)
                if point(2) > compared_point(2)
                    CorrespondPoint = [point(1); 0];
                elseif point(2) < compared_point(2)
                    CorrespondPoint = [point(1); size(app.InputImage,2)];
                else
                    CorrespondPoint = point;
                end
                return;
            else
                k = (point(2)-compared_point(2))/(point(1)-compared_point(1));
                b = point(2)-k*point(1);
                if point(1) > compared_point(1)
                    phi = atan((point(2)-compared_point(2))/(point(1)-compared_point(1)));
                    theta_1 = atan((compared_point(2)-size(app.InputImage,1))/(compared_point(1)-0));
                    theta_2 = atan((compared_point(2)-0)/(compared_point(1)-0));
                    if phi < theta_1
                        % edge below
                        CorrespondPoint = [(size(app.InputImage,1)-b)/k; size(app.InputImage,1)];
                        % outer leftside
                        CorrespondPoint_Outer = [0; b];
                    elseif phi >= theta_1 && phi < 0
                        % edge leftside
                        CorrespondPoint = [0; b];
                        % outer below
                        CorrespondPoint_Outer = [(size(app.InputImage,1)-b)/k; size(app.InputImage,1)];
                    elseif phi >= 0 && phi < theta_2
                        % edge leftside
                        CorrespondPoint = [0; b];
                        % outer above
                        CorrespondPoint_Outer = [-b/k; 0];
                    else
                        % edge above
                        CorrespondPoint = [-b/k; 0];
                        % outer leftside
                        CorrespondPoint_Outer = [0; b];
                    end
                else
                    phi = atan((point(2)-compared_point(2))/(point(1)-compared_point(1)));
                    theta_1 = atan((compared_point(2)-0)/(compared_point(1)-size(app.InputImage,2)));
                    theta_2 = atan((compared_point(2)-size(app.InputImage,1))/(compared_point(1)-size(app.InputImage,2)));
                    if phi < theta_1
                        % edge above
                        CorrespondPoint = [-b/k; 0];
                        % outer right side
                        CorrespondPoint_Outer = [size(app.InputImage,2); k*size(app.InputImage,2)+b];
                    elseif phi >= theta_1 && phi < 0
                        % edge right side
                        CorrespondPoint = [size(app.InputImage,2); k*size(app.InputImage,2)+b];
                        % outer above
                        CorrespondPoint_Outer = [-b/k; 0];
                    elseif phi >= 0 && phi < theta_2
                        % edge right side
                        CorrespondPoint = [size(app.InputImage,2); k*size(app.InputImage,2)+b];
                        % outer below
                        CorrespondPoint_Outer = [(size(app.InputImage,1)-b)/k; size(app.InputImage,1)];
                    else
                        % edge below
                        CorrespondPoint = [(size(app.InputImage,1)-b)/k; size(app.InputImage,1)];
                        % outer right side
                        CorrespondPoint_Outer = [size(app.InputImage,2); k*size(app.InputImage,2)+b];
                    end
                end
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            title(app.UIAxes,'');
            xlabel(app.UIAxes,'');
            ylabel(app.UIAxes,'');       
            
            app.radial_size = 4;

            app.space = false;
            app.stop_motion_VP_RL = false;
            
            % flags of drawing
            app.drawVP_flag = false;
            app.drawRW_flag = false;
            app.drawRL_flag = false;
            app.drawPO_flag = false;
            app.drawFO_flag = false;
            app.draw_moveable_flag = false;
            
            % drawing points and verticies 
            app.draw_radial = zeros(4*app.radial_size+4,1);
            app.draw_polygons = zeros(5,1);
            app.draw_vertices = zeros(12,1);
            
            app.VanishPoint = zeros(2,1);
            app.MovingPoint = zeros(2,1);
            app.OuterRect = zeros(2,4);
            app.OuterFixies = zeros(2,app.radial_size*4);
            app.InnerRect = zeros(2,4);
            app.InnerCorrespond = zeros(2,4);
            app.OuterCorrespond = zeros(2,4);
            app.Verticies = zeros(2, 12);
            app.Coordination = zeros(3, 12);
            app.ForegroundObj = {};
            
            % plot 
            app.UIFigure.WindowStyle = 'normal';
        end

        % Window button motion function: UIFigure
        function UIFigureWindowButtonMotion(app, event)
            % update the VP
            try
                if ~app.stop_motion_VP_RL
                    if ~app.space
                        app.specify_VanishPoint();
                        % update the inner rectangle 
                        app.specify_RearWindow();
                    else
                        app.specify_RadialLines();
                    end
                end
            catch
            end
        end

        % Window key press function: UIFigure
        function UIFigureWindowKeyPress(app, event)
            key = event.Key;
            if strcmp(key,'space')
                app.space = true;
            end
        end

        % Window key release function: UIFigure
        function UIFigureWindowKeyRelease(app, event)
            key = event.Key;
            if strcmp(key,'space')
                app.space = false;
            end
        end

       

      

        % On callback: ToggleTool
        function ToggleToolOn(app, event)
            app.space = true;
        end

        % Off callback: ToggleTool
        function ToggleToolOff(app, event)
            app.space = false;
        end

           % Button pushed function: OpenFileButton
        function OpenFileButtonPushed(app, event)
            [file,path,FilterIndex] = uigetfile('*.png;*.tif;*bmp;*gif;*.jpg','Select an Image File');
            if FilterIndex == 0
                return;
            end
            app.InputImage = imread(fullfile(path,file));
            app.startupFcn();
            imshow(app.InputImage,'Parent',app.UIAxes);
            app.specify_OuterRectangle();
            app.initialize_RearWindow_and_VanishPoint();
            [rows,cols,~]=size(app.InputImage);
            app.cell_with3Dpoints=cell(rows,cols);
            app.cell_with3Dpoints(:,:)={0};
            app.flag3DModel=false;
            app.CreateGridModelButton.Enable = true;
        end

        % Button pushed function: CreateGridModelButton
        function CreateGridModelButtonPushed(app, event)
            app.loadingLabel.Visible = true;
            app.loadingIcon.Visible = true;
            pause(0.01)
            app.stop_motion_VP_RL = true;
            app.clear_drawing('all');
            app.specify_Polygons();
            pause(0.01)
            app.calculate3Dverticies();
            app.flag3DModel=true;
            %app.CreateForegroundMaskButton.Enable = true;

            
            
            
            if app.drawPO_flag
                % calculate 3D points
                app.calculate3DPoints();
                % stacking the matrix columns
                World_r = reshape(app.matrix_with3Dpoints(:,:,1),[],1);
                World_g = reshape(app.matrix_with3Dpoints(:,:,2),[],1);
                World_b = reshape(app.matrix_with3Dpoints(:,:,3),[],1);
                Color_r = reshape(app.InputImage(:,:,1),[],1);
                Color_g = reshape(app.InputImage(:,:,2),[],1);
                Color_b = reshape(app.InputImage(:,:,3),[],1);
                World = double([World_r, World_g, World_b]);
                Color = double([Color_r, Color_g, Color_b]);
                app.points3D_and_colormap = double([World, Color]);
                
                %TODO
                % app.draw_cam = drawpoint(app.UIAxes, 'Position', app.CameraPoint,'InteractionsAllowed','none','Label','Camera');
                
                
                app.CamXSlider.Enable = true;
                app.CamYSlider.Enable = true;
                app.CamZSlider.Enable = true;
                app.PitchSlider.Enable = true;
                app.YawSlider.Enable = true;
                app.RenderImageButton.Enable = true;
                
                % uncomment to plot 3D image
                %scatter3(app.points3D_and_colormap(:,1), app.points3D_and_colormap(:,2), app.points3D_and_colormap(:,3), 20, app.points3D_and_colormap(:,4:6)/255, 'fill');
                
                app.loadingLabel.Visible = false;
                app.loadingIcon.Visible = false;
            end
        end

        % Button pushed function: CreateForegroundMaskButton
%         function CreateForegroundMaskButtonPushed(app, event)
%             % TODO
%         end

%         Value changed function: CamXSlider
        function CamXSliderValueChanged(app, event)
            app.update_CameraPoint();
        end

        % Value changed function: CamYSlider
        function CamYSliderValueChanged(app, event)
            app.update_CameraPoint();            
        end

        % Value changed function: CamZSlider
        function CamZSliderValueChanged(app, event)
            app.update_CameraPoint();
        end

        % Value changed function: PitchSlider
        function PitchSliderValueChanged(app, event)
            value = app.PitchSlider.Value;
            
        end

        % Value changed function: YawSlider
        function YawSliderValueChanged(app, event)
            value = app.YawSlider.Value;
            
        end

        % Button pushed function: RenderImageButton
        function RenderImageButtonPushed(app, event)
            app.loadingLabel.Visible = true;
            app.loadingIcon.Visible = true;
            pause(0.01)
            pos = [app.CamXSlider.Value / 100 * size(app.InputImage, 2), 
                   app.CamYSlider.Value / 100 * size(app.InputImage, 1),
                   app.CamZSlider.Value /  50 * max(app.points3D_and_colormap(:, 3)) + 1000]; %TODO replace 1000 with f
            ang = [app.PitchSlider.Value, app.YawSlider.Value];
            projected = projection(app.points3D_and_colormap, pos, ang);

            projected = ([-1, 0, 0, 0, 0;
                          0, 1, 0, 0, 0;
                          0, 0, 1, 0, 0;
                          0, 0, 0, 1, 0;
                          0, 0, 0, 0, 1] * projected')';
            
            ret = fillimage(projected);
            mask = isnan(ret(:, :, 1));
            
            ret_r = double(ret(:, :, 1));
            ret_g = double(ret(:, :, 2));
            ret_b = double(ret(:, :, 3));
            ret_r = regionfill(ret_r, mask);
            ret_g = regionfill(ret_g, mask);
            ret_b = regionfill(ret_b, mask);
            
            recombinedimg(:, :, 1) = uint8(ret_r);
            recombinedimg(:, :, 2) = uint8(ret_g);
            recombinedimg(:, :, 3) = uint8(ret_b);
            
            imtool(recombinedimg);
            app.loadingLabel.Visible = false;
            app.loadingIcon.Visible = false;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1082 665];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.WindowButtonMotionFcn = createCallbackFcn(app, @UIFigureWindowButtonMotion, true);
            app.UIFigure.WindowKeyPressFcn = createCallbackFcn(app, @UIFigureWindowKeyPress, true);
            app.UIFigure.WindowKeyReleaseFcn = createCallbackFcn(app, @UIFigureWindowKeyRelease, true);

            % Create Toolbar
            app.Toolbar = uitoolbar(app.UIFigure);
        
            % Create ToggleTool
            app.ToggleTool = uitoggletool(app.Toolbar);
            app.ToggleTool.Tooltip = {'Enable the movement for lower radial line (holding space bar has same functionality)'; ''};
            app.ToggleTool.Icon = '84-847218_computer-mouse-computer-icons-pointer-point-and-click-cursor-drag-and-drop.png';
            app.ToggleTool.OffCallback = createCallbackFcn(app, @ToggleToolOff, true);
            app.ToggleTool.OnCallback = createCallbackFcn(app, @ToggleToolOn, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'2.14x', '1x'};
            app.GridLayout.RowHeight = {'8.46x', '1x'};
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [10 0 10 0];

            % Create UIAxes
            app.UIAxes = uiaxes(app.GridLayout);
            title(app.UIAxes, 'Picture')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Layout.Row = [1 2];
            app.UIAxes.Layout.Column = 1;

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.GridLayout);
            app.ButtonGroup.Tooltip = {''};
            app.ButtonGroup.Layout.Row = [1 2];
            app.ButtonGroup.Layout.Column = 2;

            % Create OpenFileButton
            app.OpenFileButton = uibutton(app.ButtonGroup, 'push');
            app.OpenFileButton.ButtonPushedFcn = createCallbackFcn(app, @OpenFileButtonPushed, true);
            app.OpenFileButton.Icon = 'folder.png';
            app.OpenFileButton.Position = [77 600 190 30];
            app.OpenFileButton.Text = 'Open File';

            % Create CreateGridModelButton
            app.CreateGridModelButton = uibutton(app.ButtonGroup, 'push');
            app.CreateGridModelButton.ButtonPushedFcn = createCallbackFcn(app, @CreateGridModelButtonPushed, true);
            app.CreateGridModelButton.Icon = 'cube.png';
            app.CreateGridModelButton.Enable = 'off';
            app.CreateGridModelButton.Tooltip = {'press this if you are done specifying the grid'};
            app.CreateGridModelButton.Position = [77 550 190 30];
            app.CreateGridModelButton.Text = 'Create Grid Model';

            % Create CreateForegroundMaskButton
%             app.CreateForegroundMaskButton = uibutton(app.ButtonGroup, 'push');
%             app.CreateForegroundMaskButton.ButtonPushedFcn = createCallbackFcn(app, @CreateForegroundMaskButtonPushed, true);
%             app.CreateForegroundMaskButton.Icon = 'flower-tulip.png';
%             app.CreateForegroundMaskButton.Enable = 'off';
%             app.CreateForegroundMaskButton.Visible = 'off';
%             app.CreateForegroundMaskButton.Tooltip = {'Creates a 3D Model of the 5 rectangles specified by the grid'};
%             app.CreateForegroundMaskButton.Position = [77 500 190 30];
%             app.CreateForegroundMaskButton.Text = 'Create Foreground Mask';

            % Create CamYSliderLabel
            app.CamYSliderLabel = uilabel(app.ButtonGroup);
            app.CamYSliderLabel.Position = [30 390 60 22];
            app.CamYSliderLabel.Text = 'Cam-Y';

            % Create CamYSlider
            app.CamYSlider = uislider(app.ButtonGroup);
            app.CamYSlider.MajorTicks = [0 20 40 60 80 100];
            app.CamYSlider.ValueChangedFcn = createCallbackFcn(app, @CamYSliderValueChanged, true);
            app.CamYSlider.Enable = 'off';
            app.CamYSlider.Tooltip = {'Choose camera y position in percentage of image size'};
            app.CamYSlider.Position = [90 400 200 3];
            app.CamYSlider.Value = 50;

            % Create CamXSliderLabel
            app.CamXSliderLabel = uilabel(app.ButtonGroup);
            app.CamXSliderLabel.Position = [30 440 60 22];
            app.CamXSliderLabel.Text = 'Cam-X';

            % Create CamXSlider
            app.CamXSlider = uislider(app.ButtonGroup);
            app.CamXSlider.MajorTicks = [0 20 40 60 80 100];
            app.CamXSlider.ValueChangedFcn = createCallbackFcn(app, @CamXSliderValueChanged, true);
            app.CamXSlider.Enable = 'off';
            app.CamXSlider.Tooltip = {'Choose camera y position in percentage of image size'};
            app.CamXSlider.Position = [90 450 200 3];
            app.CamXSlider.Value = 50;

            % Create CamZSliderLabel
            app.CamZSliderLabel = uilabel(app.ButtonGroup);
            app.CamZSliderLabel.Position = [30 340 60 22];
            app.CamZSliderLabel.Text = 'Cam-Z';

            % Create CamZSlider
            app.CamZSlider = uislider(app.ButtonGroup);
            app.CamZSlider.MajorTicks = [0 20 40 60 80 100];
            app.CamZSlider.ValueChangedFcn = createCallbackFcn(app, @CamZSliderValueChanged, true);
            app.CamZSlider.Enable = 'off';
            app.CamZSlider.Tooltip = {'Choose camera y position in percentage of image size'};
            app.CamZSlider.Position = [90 350 200 3];
            app.CamZSlider.Value = 50;

            % Create PitchSliderLabel
            app.PitchSliderLabel = uilabel(app.ButtonGroup);
            app.PitchSliderLabel.Position = [30 290 60 22];
            app.PitchSliderLabel.Text = 'Pitch';

            % Create PitchSlider
            app.PitchSlider = uislider(app.ButtonGroup);
            app.PitchSlider.Limits = [-30 30];
            app.PitchSlider.MajorTicks = [-30 -20 -10 0 10 20 30];
            app.PitchSlider.ValueChangedFcn = createCallbackFcn(app, @PitchSliderValueChanged, true);
            app.PitchSlider.Enable = 'off';
            app.PitchSlider.Tooltip = {'Choose camera y position in percentage of image size'};
            app.PitchSlider.Position = [90 300 200 3];

            % Create YawSliderLabel
            app.YawSliderLabel = uilabel(app.ButtonGroup);
            app.YawSliderLabel.Position = [30 240 60 22];
            app.YawSliderLabel.Text = 'Yaw';

            % Create YawSlider
            app.YawSlider = uislider(app.ButtonGroup);
            app.YawSlider.Limits = [-30 30];
            app.YawSlider.MajorTicks = [-30 -20 -10 0 10 20 30];
            app.YawSlider.ValueChangedFcn = createCallbackFcn(app, @YawSliderValueChanged, true);
            app.YawSlider.Enable = 'off';
            app.YawSlider.Tooltip = {'Choose camera y position in percentage of image size'};
            app.YawSlider.Position = [90 250 200 3];

            % Create RenderImageButton
            app.RenderImageButton = uibutton(app.ButtonGroup, 'push');
            app.RenderImageButton.ButtonPushedFcn = createCallbackFcn(app, @RenderImageButtonPushed, true);
            app.RenderImageButton.Icon = 'magic-wand.png';
            app.RenderImageButton.Enable = 'off';
            app.RenderImageButton.Tooltip = {'Creates a 3D Model of the 5 rectangles specified by the grid'};
            app.RenderImageButton.Position = [32 130 271 45];
            app.RenderImageButton.Text = 'Render Image';

            % Create loadingLabel
            app.loadingLabel = uilabel(app.ButtonGroup);
            app.loadingLabel.FontSize = 16;
            app.loadingLabel.Visible = 'off';
            app.loadingLabel.Position = [62 36 175 21];
            app.loadingLabel.Text = 'loading';

            % Create loadingIcon
            app.loadingIcon = uiimage(app.ButtonGroup);
            app.loadingIcon.Visible = 'off';
            app.loadingIcon.Position = [30 34 25 25];
            app.loadingIcon.ImageSource = 'loading.png';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = main
            
            % include subfolders
            addpath(genpath(pwd))

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
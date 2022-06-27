disp('started')

% Run GUI app
gui_test

disp('done')

%%% FUNCTIONS %%%

function mask = update_mask(subtract, main_mask, new_mask)
    % adds or subtracts new_mask to main_mask
    %
    % :param main_mask: binary mask image
    % :param new_mask: binary mask image of same size with object to be
    % added/removed
    % :param subtract: boolean 0=add, 1=subtract
    if (subtract)
        mask = main_mask - new_mask;
    else
        mask = main_mask + new_mask;
    end
end

function fix_line(line, lines)
    % fixes one of the 4 spider lines (through vanish point and inner rectangle corner)
    % and sets the other 3 free
    % 
    % :param line: line object to be fixed
    % :param lines: all 4 lines
end

function lines = update_lines(fixed, lines)
    % update the 4 spider lines depending on new line 
    
    
end
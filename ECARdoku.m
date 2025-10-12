% ECARdoku: Elementary Cellular Automata Sudoku-like Puzzle
% This script simulates all possible m x n boards for reversible Rule 37
% with periodic boundaries, starting from all possible initial rows.
% It precomputes all boards, then interactively prompts for constraints
% (row, column, value) and filters the possible boards accordingly.
% It outputs the number of possible boards after each valid constraint.
% If a constraint leads to zero possibilities, it discards it and prompts again.
% The script ends when exactly one possible board remains.
% Displays the final board and saves it as a large image (100m x 100n pixels).

% Hardwired parameters
rule = 37;          % Rule number
n = 8;              % Width (number of columns)
m = 6;              % Generations (number of rows)
num_initial = 2^n;  % Initial number of possible boards

% Display initial count
disp(['Initial number of possible boards: ' num2str(num_initial)]);

% Extract the rule bits
rule_bits = bitget(rule, 1:8);

% Precompute all possible boards
boards = zeros(num_initial, m, n);
for k = 0:num_initial-1
    grid = zeros(m, n);
    
    % Set initial row (row 1), with MSB at column 1
    for col = 1:n
        grid(1, col) = bitget(k, n - col + 1);
    end
    
    % Simulate forward (reversible mode)
    for t = 1:m-1
        for x = 1:n
            % Periodic boundaries
            left = mod(x-2, n) + 1;
            right = mod(x, n) + 1;
            
            % Neighborhood value
            neigh = grid(t, left) * 4 + grid(t, x) * 2 + grid(t, right) * 1;
            
            % Rule output
            rule_output = rule_bits(neigh + 1);
            
            % XOR term
            if t == 1
                xor_term = 0;
            else
                xor_term = grid(t-1, x);
            end
            
            % Set next state
            grid(t+1, x) = bitxor(rule_output, xor_term);
        end
    end
    
    boards(k+1, :, :) = grid;
end

% Initialize possible indices
possible_indices = 1:num_initial;

% Preallocate clues
max_clues = m * n;
clues = zeros(max_clues, 3);
clue_count = 0;

% Prompt for mode
mode = input('Enter 0 for manual clues, 1 for random: ');

if mode == 0
    % Manual mode
    while true
        % Prompt for input
        row = input(sprintf('Enter row (1-%d): ', m));
        col = input(sprintf('Enter column (1-%d): ', n));
        val = input('Enter value (0 or 1): ');
        
        % Validate input
        if row < 1 || row > m || col < 1 || col > n || (val ~= 0 && val ~= 1)
            fprintf('Invalid input. Row must be between 1 and %d, column between 1 and %d, value must be 0 or 1.\n', m, n);
            continue;
        end
        
        % Test the new constraint
        vals = squeeze(boards(possible_indices, row, col));
        temp_possible = possible_indices(vals == val);
        count = length(temp_possible);
        
        if count > 0
            % Update possible indices and add clue
            possible_indices = temp_possible;
            clue_count = clue_count + 1;
            clues(clue_count, :) = [row col val];
            disp(['Number of possible boards: ' num2str(count)]);
            
            % Check if done
            if isscalar(possible_indices)
                disp('One unique board remains.');
                break;
            end
        else
            disp('No possible board remains with this constraint.');
        end
    end
else
    % Random mode
    constrained = false(m, n);
    while numel(possible_indices) > 1
        available = find(~constrained);
        if isempty(available)
            disp('Exhausted all positions without unique board.');
            break;
        end
        
        idx = randi(length(available));
        [row, col] = ind2sub([m n], available(idx));
        val = randi([0 1]);
        
        % Test the new constraint
        old_count = numel(possible_indices);
        vals = squeeze(boards(possible_indices, row, col));
        temp_possible = possible_indices(vals == val);
        count = length(temp_possible);
        
        if count > 0 && count < old_count
            % Update possible indices, add clue, and constrain
            possible_indices = temp_possible;
            clue_count = clue_count + 1;
            clues(clue_count, :) = [row col val];
            constrained(row, col) = true;
            disp(['Added random clue: Row ' num2str(row) ', Column ' num2str(col) ', Value ' num2str(val)]);
            disp(['Number of possible boards: ' num2str(count)]);
        elseif count == 0
            disp('No possible board remains with this constraint.');
        end  % else redundant, skip
    end
    if isscalar(possible_indices)
        disp('One unique board remains.');
    end
end

% Trim clues
clues = clues(1:clue_count, :);

% Save clues to file if unique board found
if isscalar(possible_indices)
    fid = fopen('clues.txt', 'w');
    if fid == -1
        error('Could not open clues.txt for writing');
    end
    for i = 1:size(clues, 1)
        fprintf(fid, '%d %d %d\n', clues(i, 1), clues(i, 2), clues(i, 3));
    end
    fclose(fid);
    disp('Final set of clues saved to clues.txt');
end

% Get the final board
final_board = squeeze(boards(possible_indices(1), :, :));

% Display the final board
figure;
imagesc(final_board);
colormap(flipud(gray));  % 0=white, 1=black
xlabel('Column');
ylabel('Row');
title('Final Unique Board');

% Save as a large image (100m x 100n pixels)
image_data = uint8((1 - final_board) * 255);  % 0 -> 255 (white), 1 -> 0 (black)
large_image = imresize(image_data, [100*m, 100*n], 'nearest');
imwrite(large_image, 'final_board.png');
disp('Final board saved as final_board.png');
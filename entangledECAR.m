clear; close all; clc;   % forces clean workspace every run

% entangledECAR: Entangled cells in Reversible Elementary Cellular Automata
% + Precomputation once + loop on target_solutions
% + Anticorrelated pairs are found, selected, colored and shown in legend
% + Saved PNG is clean board only (100x100 pixels per cell, no legend)

% Hardwired parameters
rule = 37;              % Rule number
n = 18;                 % Width (number of columns)
m = 18;                 % Generations (number of rows)
show_entanglement = true;

num_initial = 2^n;

% === MEMORY ESTIMATE & LARGE BOARD WARNING ===
memory_bytes = num_initial * m * n;
memory_gb = memory_bytes / (1024^3);
fprintf('⚠️  LARGE BOARD (n=%d): Precomputing %d boards...\n', n, num_initial);
fprintf('Estimated RAM for boards array: %.2f GB\n', memory_gb);
fprintf('Precomputation will take a few minutes...\n\n');

if n >= 18
    confirm = input('Continue with this large computation? (y/n): ', 's');
    if isempty(confirm) || lower(confirm(1)) ~= 'y' && lower(confirm(1)) ~= '1'
        disp('Aborted by user.');
        return;
    end
end

% ==================== PRECOMPUTE ALL BOARDS (ONCE) ====================
fprintf('Precomputing boards...\n');
h = waitbar(0, sprintf('Precomputing %d boards (n=%d m=%d)...', num_initial, n, m));

boards = zeros(num_initial, m, n, 'uint8');
rule_bits = bitget(rule, 1:8);

for k = 0:num_initial-1
    grid = zeros(m, n, 'uint8');
    for col = 1:n
        grid(1, col) = bitget(k, n - col + 1);
    end
    for t = 1:m-1
        for x = 1:n
            left  = mod(x-2, n) + 1;
            right = mod(x,   n) + 1;
            neigh = grid(t,left)*4 + grid(t,x)*2 + grid(t,right)*1;
            rule_output = rule_bits(neigh + 1);
            if t == 1
                xor_term = 0;
            else
                xor_term = grid(t-1, x);
            end
            grid(t+1, x) = bitxor(rule_output, xor_term);
        end
    end
    boards(k+1, :, :) = grid;
    if mod(k, max(1, round(num_initial/100))) == 0
        waitbar((k+1)/num_initial, h);
        drawnow;
    end
end
close(h);
disp('Precomputation finished. Ready for multiple targets.');

% ====================== MAIN LOOP ======================
while true
    target_str = input('\nEnter target number of solutions (or press Enter to exit): ', 's');
    if isempty(target_str)
        disp('Exiting. Goodbye!');
        break;
    end
    target_solutions = str2double(target_str);
    if isnan(target_solutions) || target_solutions < 2
        disp('Invalid input. Please enter a number >= 2.');
        continue;
    end
    
    fprintf('\n=== Starting new run with target = %d ===\n', target_solutions);
    
    % === Manual / Random mode for this target ===
    possible_indices = 1:num_initial;
    max_clues = m * n;
    clues = zeros(max_clues, 3);
    clue_count = 0;
    
    mode = input('Enter 0 for manual clues, 1 for random: ');
    
    if mode == 0
        while true
            row = input(sprintf('Enter row (1-%d): ', m));
            col = input(sprintf('Enter column (1-%d): ', n));
            val = input('Enter value (0 or 1): ');
            if row < 1 || row > m || col < 1 || col > n || (val ~= 0 && val ~= 1)
                fprintf('Invalid input.\n'); continue;
            end
            vals = squeeze(boards(possible_indices, row, col));
            temp_possible = possible_indices(vals == val);
            count = length(temp_possible);
            if count > 0
                possible_indices = temp_possible;
                clue_count = clue_count + 1;
                clues(clue_count, :) = [row col val];
                disp(['Number of possible boards: ' num2str(count)]);
                if count <= target_solutions
                    disp('Target reached. Stopping.');
                    break;
                end
            else
                disp('No possible board remains with this constraint.');
            end
        end
    else
        constrained = false(m, n);
        while numel(possible_indices) > target_solutions
            available = find(~constrained);
            if isempty(available), break; end
            idx = randi(length(available));
            [row, col] = ind2sub([m n], available(idx));
            val = randi([0 1]);
            old_count = numel(possible_indices);
            vals = squeeze(boards(possible_indices, row, col));
            temp_possible = possible_indices(vals == val);
            count = length(temp_possible);
            if count > 0 && count < old_count && count >= target_solutions
                possible_indices = temp_possible;
                clue_count = clue_count + 1;
                clues(clue_count, :) = [row col val];
                constrained(row, col) = true;
                disp(['Added random clue: Row ' num2str(row) ', Col ' num2str(col) ', Val ' num2str(val)]);
                disp(['Number of possible boards: ' num2str(count)]);
            elseif count == 0
                disp('No possible board remains with this constraint.');
            end
        end
    end
    
    % Trim clues
    clues = clues(1:clue_count, :);
    if clue_count > 0
        fid = fopen('clues.txt', 'w');
        for i = 1:size(clues,1)
            fprintf(fid, '%d %d %d\n', clues(i,:));
        end
        fclose(fid);
        disp('Clues saved to clues.txt');
    end
    
    % ====================== DISPLAY + ENTANGLEMENT ======================
    num_sol = numel(possible_indices);
    if num_sol >= 2
        remaining = boards(possible_indices, :, :);
        board_min = squeeze(min(remaining, [], 1));
        board_max = squeeze(max(remaining, [], 1));
        all_agree = (board_min == board_max);
        
        display_board = ones(m, n);
        display_board(all_agree & board_min == 0) = 0;
        display_board(all_agree & board_min == 1) = 2;
        
        if show_entanglement
            [ind_r, ind_c] = find(~all_agree);
            [~, sort_idx] = sortrows([ind_r ind_c]);   % row-major order (clusters in first rows)
            ind_r = ind_r(sort_idx);
            ind_c = ind_c(sort_idx);
            
            num_ind = length(ind_r);
            max_possible_pairs = num_ind*(num_ind-1)/2;
            candidate_pairs = zeros(max_possible_pairs, 5, 'double');
            pair_idx = 0;
            
            for p1 = 1:num_ind
                for p2 = p1+1:num_ind
                    v1 = squeeze(remaining(:, ind_r(p1), ind_c(p1)));
                    v2 = squeeze(remaining(:, ind_r(p2), ind_c(p2)));
                    if all(v1 == v2)
                        pair_idx = pair_idx + 1;
                        candidate_pairs(pair_idx, :) = [ind_r(p1) ind_c(p1) ind_r(p2) ind_c(p2) 1];
                    elseif all(v1 ~= v2)
                        pair_idx = pair_idx + 1;
                        candidate_pairs(pair_idx, :) = [ind_r(p1) ind_c(p1) ind_r(p2) ind_c(p2) 2];
                    end
                end
            end
            candidate_pairs = candidate_pairs(1:pair_idx, :);
            
            % === IGNORE CORRELATED PAIRS COMPLETELY ===
            % Keep ONLY anticorrelated pairs
            candidate_pairs = candidate_pairs(candidate_pairs(:,5) == 2, :);
            
            % Even distribution — NO artificial constraints (max 4 per row, first-row rules)
            max_pairs = 8;
            used = false(m, n);
            selected_pairs = zeros(max_pairs, 5, 'double');
            sel_idx = 0;
            
            for i = 1:size(candidate_pairs,1)
                if sel_idx >= max_pairs, break; end
                r1 = candidate_pairs(i,1); c1 = candidate_pairs(i,2);
                r2 = candidate_pairs(i,3); c2 = candidate_pairs(i,4);
                if ~used(r1,c1) && ~used(r2,c2)
                    sel_idx = sel_idx + 1;
                    selected_pairs(sel_idx, :) = candidate_pairs(i, :);
                    used(r1,c1) = true; used(r2,c2) = true;
                end
            end
            selected_pairs = selected_pairs(1:sel_idx, :);
            
            % === ONLY ANTICORRELATED PAIRS ARE COLORED (full bright palette) ===
            pair_colors = [1 0 0; 1 0.65 0; 1 1 0; 1 0 1; 0 1 1; 0 0.5 1; 0 1 0; 0.5 0 1];
            
            for p = 1:size(selected_pairs,1)
                r1 = selected_pairs(p,1); c1 = selected_pairs(p,2);
                r2 = selected_pairs(p,3); c2 = selected_pairs(p,4);
                color_idx = 2 + p;
                display_board(r1,c1) = color_idx;
                display_board(r2,c2) = color_idx;
            end
        end
        
        % Main figure (on-screen only)
        base_cmap = [1 1 1; 0.5 0.5 0.5; 0 0 0];
        if show_entanglement && ~isempty(selected_pairs)
            cmap = [base_cmap; pair_colors(1:size(selected_pairs,1), :)];
        else
            cmap = base_cmap;
        end
        
        fig = figure;
        imagesc(display_board);
        colormap(cmap);
        clim([0 size(cmap,1)-1]);
        axis equal tight;
        xlabel('Column');
        ylabel('Row');
        title(sprintf('quantumECAR - %d Solutions (%d×%d)', num_sol, m, n));
        
        % Colorbar (on screen only) — now only shows the actual anticorrelated pairs
        num_pairs = size(selected_pairs,1);
        tickLabels = cell(1, 3 + num_pairs);
        tickLabels{1} = '0 (white)';
        tickLabels{2} = 'Indeterminate (grey)';
        tickLabels{3} = '1 (black)';
        for p = 1:num_pairs
            tickLabels{3+p} = sprintf('Pair %d', p);
        end
        colorbar('Ticks', 0:length(tickLabels)-1, 'TickLabels', tickLabels);
        
        % === SAVE CLEAN BOARD ONLY (100x100 pixels per cell) ===
        filename = sprintf('%d_solutions_board.png', num_sol);
        rgb_image = ind2rgb(display_board + 1, cmap);
        large_image = imresize(rgb_image, [100*m, 100*n], 'nearest');
        imwrite(large_image, filename);
        disp(['Board saved as ' filename ' (clean 100x100 pixels per cell)']);
        
        % Individual solutions display
        figure('Name', 'Individual Remaining Solutions');
        rows = ceil(num_sol / 2);
        cols = 2;
        for i = 1:num_sol
            subplot(rows, cols, i);
            board = squeeze(remaining(i, :, :));
            imagesc(board);
            colormap([1 1 1; 0 0 0]);
            axis equal tight;
            title(sprintf('Solution %d', i));
        end
        sgtitle(sprintf('All %d Remaining Solutions', num_sol));
        
        disp('Individual solution boards displayed in a separate figure.');
    else
        disp('Did not reach at least 2 boards.');
    end
end
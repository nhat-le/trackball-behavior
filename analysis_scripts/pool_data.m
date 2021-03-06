% This script reads the raw .mat files in the specified folder
% and pools all trials from the different sessions.
% It plots the empirical performance and saves the pooled data
% as a .mat file

%% Find all behavior files with varying contrasts
clear all
mouse = input('Enter mouse number: ');

switch getenv('computername')
    case 'DESKTOP-FN1P6HD'
        root = 'C:\Users\Sur lab\Dropbox (MIT)\trackball-behavior';
    case 'BEHAVE-BALL2'
        root = 'C:\Dropbox\nhat';
    otherwise
        root = 'C:\Users\Le\Dropbox (MIT)\trackball-behavior';
end


switch mouse
    case 91
        parent_folder = sprintf('%s%s', root, '\Data\80_91_ACC\91_RACC');
    case 80
        parent_folder = sprintf('%s%s', root, '\Data\80_91_ACC\80_LACC');
    case '13L'
        parent_folder = sprintf('%s%s', root, '\Data\C13\laser_analys_FebMar2019_left');
    case '13R'
        parent_folder = sprintf('%s%s', root, '\Data\C13\laser_analys_FebMar2019_right');
    case '13Apr'
        parent_folder = sprintf('%s%s', root, '\Data\C13\Apr2019');
    case '13Jun'
        parent_folder = sprintf('%s%s', root, '\Data\C13\Jun2019');
    case 87
        parent_folder = sprintf('%s%s', root, '\Data\87_89_SC\87_RSC');
    case 89
        parent_folder = sprintf('%s%s', root, '\Data\87_89_SC\89_LSC');
    
    otherwise
        error('Invalid mouse number');
end


saveFileName = 'Mouse080_behavior.mat';
load_all = 1; %Load all files, regardless of laser
load_laser = 1; %load only files with laser
checkstim = 0;

colors = linspecer(2);
colors(3,:) = [0 0 0];
addpath(pwd);

% Load info
%% Find folders with correct trackball_data
twostim_files = get_twostim_files(parent_folder, load_all);

%% Do checkups on sessions with contrasts
k = 0;
sessions = [];
animals = {};

for i = 1:size(twostim_files,2)
    load(twostim_files{i});
    if checkstim
        [output, output_details(i,:)] = check_twostim(data);
    else
        output = 1;
    end

    if output
        fprintf('Adding file %s...\n', twostim_files{i});
        animals{end+1} = data.mouse;
        k = k + 1;
        sessions{k} = twostim_files{i};
    else
        fprintf('REJECTED: %s...\n', twostim_files{i});
    end
end


%%
all_animals = unique(animals);
throw_away = [];
for i = 1:numel(throw_away)
    all_animals(all_animals == throw_away(i)) = [];
end


k = 0; all_cons = []; all_perf = [];
figure;

%   Average by animals
all_cons = []; all_perf = [];
for i = 1:numel(all_animals)
    %curr_animals = animals == all_animals(i);
    curr_files = sessions; %sessions(curr_animals);
    sess_cons = []; 
    % Looping through the behavior files.
    sess_perfC1 = 0;
    sess_perfC2 = 0;
    
    nrows = ceil(sqrt(size(curr_files, 2)));
    ncols = ceil(size(curr_files, 2) / nrows);
    
    for ii = 1:size(curr_files,2)
        % Load the file
        figure;
        load(curr_files{ii});
        
        % Determine if the file belongs to condition 1 or 2
        C = strsplit(curr_files{ii}, '\');
        filename = strsplit(C{end}, '_');

        % Get number correct in incorrect 
        con_perf_NL = get_twostim_perf(data, 0);
        con_perf_laser = get_twostim_perf(data, 1);
        
        target_con = data.params.contrast;
        disp(target_con);
        
        if target_con ~= 0.64
            fprintf('Target contrast is not 0.64, skipping...\n');
            continue;
        end
        
        [luminanceNL, perfNL, ntrialsNL, nleftNL] = get_perf_from_arr(con_perf_NL, target_con);
        [luminanceL, perfL, ntrialsL, nleftL] = get_perf_from_arr(con_perf_laser, target_con);
        
        Curr_perf_NL{ii} = perfNL;
        Curr_perf_laser{ii} = perfL;
        NtrialsNL{ii} = ntrialsNL';
        NleftNL{ii} = nleftNL';
        NtrialsL{ii} = ntrialsL';
        NleftL{ii} = nleftL';
         
        
        %subplot(nrows, ncols, ii);
        l1 = plot(luminanceL, perfL, 'b', 'LineWidth', 2);
        hold on;
        l2 = plot(luminanceNL, perfNL, 'k', 'LineWidth', 2);
        
        xlabel('Luminance diff.', 'FontSize', 16);
        ylabel('% left selected', 'FontSize', 16);
        
        filename = curr_files{ii};
        splits = strsplit(filename, '\');
        date = splits{end}(1:8);
        title(sprintf('Session %d', ii), 'FontSize', 16)
        
%         if isfield(data.params, 'laser_power')
            %title(sprintf('Date: %s, power: %s', date, data.params.laser_power));
%         else
            %title(sprintf('Date: %s', date));
%         end


%         if ii == 13
%             legend([l1, l2], {'Laser', 'No laser'}, 'FontSize', 16)
%         end
        box off
        set(gca,'tickdir','out','ticklength',[0.01 0],'xTick',[-0.64:0.32:0.64],'yTick',[0:0.5:1],...
            'ColorOrder', colors);
        xlim([-1 1]);
        ylim([-0.1 1]);
        hline(0.5);
        vline(0);
        
        saveas(gcf, [num2str(all_animals) '_session', num2str(ii), '_perf.pdf']);

    end
end




%% Perform an average across days
ntrialsNL_arr = cell2mat(NtrialsNL);
ntrialsL_arr = cell2mat(NtrialsL);
nleftNL_arr = cell2mat(NleftNL);
nleftL_arr = cell2mat(NleftL);

ntrialsNL_total = sum(ntrialsNL_arr, 2);
ntrialsL_total = sum(ntrialsL_arr, 2);
nleftNL_total = sum(nleftNL_arr, 2);
nleftL_total = sum(nleftL_arr, 2);

perfNL_total = nleftNL_total ./ ntrialsNL_total;
perfL_total = nleftL_total ./ ntrialsL_total;

% Plot the aggregate performance
figure;
l1 = plot(luminanceL, perfL_total, 'o', 'Color', colors(1,:));
hold on
l2 = plot(luminanceNL, perfNL_total, 'o', 'Color', colors(2,:));
legend([l1, l2], {'Laser', 'No laser'});


%% Plot bias across sessions
bias_laser = sum(nleftL_arr, 1) ./ sum(ntrialsL_arr, 1);
bias_nolaser = sum(nleftNL_arr, 1) ./ sum(ntrialsNL_arr, 1);

figure;
plot(1- bias_laser, 'b', 'LineWidth', 2);
hold on;
plot(1- bias_nolaser, 'k', 'LineWidth', 2);
xlabel('Session #', 'FontSize', 16);
ylabel('% choose left', 'FontSize', 16);
title(['Mouse ' num2str(all_animals)], 'FontSize', 16);
%legend({'Laser', 'No laser'});
    



%% Save the parameters
filename = input('Enter the name of the file, 0 to skip saving: ');
if ischar(filename)
    save(filename, 'luminanceL', 'luminanceNL', ...
        'nleftNL_total', 'nleftL_total',...
        'ntrialsNL_total', 'ntrialsL_total');
end


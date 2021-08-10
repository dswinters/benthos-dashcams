% Timestamps in the GPS+SENSORS_V2 data format tend to skip around by a second
% or so. Data appears to be in order, but timestamps are not.
%
% Try to fix this by identifying individual sensor bursts and re-constructing
% timestamps sequences given the known sample rate.
%

function [dn, burst_num, burst_type_num, burst_types] = ornitela_v2_timestamp_correction(T)

% Identify unique data types
dtypes = categories(T.datatype);
dtype_idx = 1:length(dtypes);
dtnum = double(T.datatype);

% Identify burst sample data types
burst_types = dtypes(find(endsWith(dtypes,'Hz')));
burst_type_idx = find(endsWith(dtypes,'Hz'));

% Make preliminary timestamps
dn = datenum([year(T.UTC_date) month(T.UTC_date) day(T.UTC_date),...
              hour(T.UTC_time) minute(T.UTC_time) second(T.UTC_time)]);

% Loop over distinct burst types
nburst = 0;
burst_type_num = nan*dn;
burst_num = nan*dn;
for i = 1:length(burst_types)

    % Get the sampling rate, e.g. extract 10 from 'SEND_ALL_10Hz'
    pat = asManyOfPattern(wildcardPattern + "_");
    rate = extractBetween(burst_types{i},pat,'Hz');
    rate = str2num(rate{1});

    % Find and number segmends with this burst datatype
    isBurst = dtnum == burst_type_idx(i);
    nburst = cumsum([isBurst(1); diff(isBurst)]>0) + max(nburst);
    nburst(~isBurst) = nan;

    % Get the datatype numbers of the start/end datatypes associated with this burst
    % type, e.g. 'SEND_ALL_10Hz_START' and 'SEND_ALL_10Hz_END' from 'SEND_ALL_10Hz'.
    start_dtnum = find(strcmp(dtypes, [burst_types{i} '_START']));
    end_dtnum = find(strcmp(dtypes, [burst_types{i} '_END']) | ...
                     strcmp(dtypes, [burst_types{i} '_ENDINT']));

    % Loop over burst segments and re-create timestamps.

    % Some of the dive segments may have multiple bursts. Make a counter to track
    % these so burst numbers are incremented properly.
    c = 0;

    for n = min(nburst):max(nburst)

        % Get the start and end indices of the burst segment
        b1 = find(nburst==n,1,'first');
        b2 = find(nburst==n,1,'last');

        % Include the burst's _START and _END entries if they exist immediately
        % before/after the burst. Don't look outside of the array range.
        if dtnum(max(1,b1-1)) == start_dtnum % Check preceeding entry
            b1 = b1-1; % Burst is preceeded by the correct _START line
        end
        if dtnum(min(length(dtnum),b1+1)) == end_dtnum % Check following entry
            b2 = b2+1; % Burst is followed by the correct _END line
        end

        % Check for segments with consecutive timestamps 2 seconds apart. This should
        % catch dive bursts that have been grouped together. Number these:
        nburst_sub = cumsum([false; diff(dn(b1:b2))*86400 > 2]);
        burst_ind = b1:b2;
        % Reconstruct timestamps for each sub burst
        for ns = 0:max(nburst_sub)
            sub_ind = burst_ind(nburst_sub==ns); % indices for sub-burst
            dn(sub_ind) = dn(sub_ind(1)) + [0:range(sub_ind)]*1/rate/86400;
        end
        burst_type_num(b1:b2) = i;
        burst_num(b1:b2) = n + c + nburst_sub;
        c = c + max(nburst_sub); % increment extra burst counter

    end % loop over bursts
end % loop over burst types

% for i = 1:length(dtypes)
%     disp(sprintf('%s: %d',dtypes{i},sum(dtnum==i)));
% end
% for i = 1:length(dtypes)
%     fprintf('%s is followed by:\n',dtypes{i})
%     u = unique(dtnum(find(dtnum(1:end-1)==i)+1));
%     for j = 1:length(u)
%         fprintf('  %s\n',dtypes{u(j)})
%     end
% end

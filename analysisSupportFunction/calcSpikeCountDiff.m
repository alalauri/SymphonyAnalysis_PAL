function tr = calcSpikeCountDiff(tr,param)
%Calculate the frequency of seeing.
%tr: subtree of analysisTree (the root being the top of DataSet (=e.g.
%LightStep_20)
%   Detailed explanation goes here
    %construct template
    if nargin==0%test purpose
        global ANALYSIS_FOLDER
        %fname = '032415Ac11.mat';
        fname = '012715Ac1.mat';
        load(fullfile(ANALYSIS_FOLDER,'analysisTrees',fname));
        tr = analysisTree;
        %stimulus_type = 'LightStep_20';
        stimulus_type = 'LightStep_5000';
        idx = find(tr.treefun(@(x)~isempty(strfind(x.name,stimulus_type))));
        tr = tr.subtree(idx);
        param.n_epoch_min = 5;%minimum # of trials required
        param.binwidth = 10;%Bin size for spike count histogram (in msec)
        param.twindow = 400;%msec
        tr = calcFOS(tr,param);
    end
    v2struct(param);
    %tr = addSpikeCountHist(tr,param.binwidth);%calculate spike count histogramspc
    %% Calculate the mean spike count and save on the root-should this be in addSpikeCOuntHist?
    childID = tr.getchildren(1);   
    %% Get template & go through each node to calculate inner product
    parent_node = tr.get(1);
    xvalue = parent_node.meanSpikeCountHist.xvalue;
%     mean_spc = parent_node.meanSpikeCountHist.value;  
    %Note: In spike timings, 0 corresponds to stimuls onset
    %(calculated in getEpochResponses_CA_PAL)
    stim_on = 0;
    stim_off = parent_node.stimOffset-parent_node.stimOnset;
    [idx_pre, idx_post, param] = get_analysis_intervals( xvalue, stim_off, param );
    
%     twindow = twindow/1000;%convert from msec to sec
%     idx_pre = stim_on-twindow <= xvalue  & xvalue < stim_on;
%     idx_post =  stim_off <= xvalue  & xvalue < stim_off+twindow;
    %mean_pre_spc = mean(mean_spc(idx_pre));%mean pre firing rate
    childID = tr.getchildren(1);
    n_child = length(childID);
    
    out_mean = NaN*ones(n_child,1);
    out_sem = out_mean;
    splitValue = out_mean;
    nEpochSet = out_mean;
    epochID_out = getExcludedEpochs(tr.get(1).cellName); 
    for nc = 1:n_child
        %% If one wants to exclude current epoch from the template
        %% need to go gack to mean_spc
        cur_node = tr.get(childID(nc));
        [~, epoch_idx_in] = setdiff(cur_node.epochID, epochID_out);
        pre_stim = cur_node.spikeCountHist.value(epoch_idx_in,idx_pre);
        n_epoch = size(pre_stim,1);
        if n_epoch < n_epoch_min
            continue;
        else
            nEpochSet(nc) = n_epoch;
        end
        post_stim = cur_node.spikeCountHist.value(epoch_idx_in,idx_post);
        spc_diff = sum(post_stim,2)-sum(pre_stim,2);
        out_mean(nc) = mean(spc_diff);
        out_sem(nc) = std(spc_diff)/sqrt(n_epoch);
        splitValue(nc) = cur_node.splitValue;
    end
    parent_node.spikecountdiff.mean = out_mean(~isnan(out_mean));
    parent_node.spikecountdiff.SEM = out_sem(~isnan(out_sem));
    parent_node.spikecountdiff.xvalue = splitValue(~isnan(splitValue));
    parent_node.spikecountdiff.Nepoch = nEpochSet(~isnan(nEpochSet));
    parent_node.spikecountdiff.param = param;
    tr = tr.set(1, parent_node);
    %plot(parent_node.RstarMean, spikecountdiff.mean,'o-')
end


function FH = plot_responses( cur_node, FHoffset )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    fig_para.FHoffset = FHoffset;
    %% plot spike count vs R*
    fig_para.nrow = 3;
    fig_para.ncol = 3;
    fig_para.nTotalGraphs = 1; 
    
    fig_para.annotation.string = cur_node.name;
%     ngph_fig = nrow*ncol;
    dat.x = cur_node.RstarMean;
    dat.y = cur_node.spikeCount_poststim_baselineSubtracted.mean;
    dat.y_error = cur_node.spikeCount_poststim_baselineSubtracted.SEM;
    
    %% Some analysis-should be done before??
    OFFcell = false;
    if sum(dat.y<0) > sum(dat.y>0)
        dat.y = -dat.y;
        OFFcell = true;
    end
    smth_winsize = 50;%msec
    PSTH_baseline_subtracted = cellfun(@(x,y) y-mean(y(x<0)), cur_node.PSTH.xvalue, cur_node.PSTH.value,'uniformoutput',false);
    [PSTH_abspeaks, idx] = cellfun(@(x)max(abs(x(1:end-1))), PSTH_baseline_subtracted);
    linidx = 1:length(idx);
    PSTH_peakvals = arrayfun(@(n,i)PSTH_baseline_subtracted{n}(i),linidx,idx);
    [PSTH_smth, npt_smth] = cellfun(@(x,y)smoothPSTH(x,y,smth_winsize),cur_node.PSTH.xvalue, cur_node.PSTH.value,'uniformoutput',false);
    npt_smth = unique(cell2mat(npt_smth));
    %% Plots
    ngph = 1;
    fig_para.xlabel.string = 'Rstar'; 
    fig_para.ylabel.string = 'Spike Count (Post stim - Pre stim)';
    %fig_para.line_prop.marker = 'o';-this doesn't work so far
    
    %Linear plot
    fig_para.title.string = 'Linear scale';
    [ngph, ~, LH] = tile_graph(dat,fig_para, @errorbar, ngph, FHoffset);
    
    %Semi-log plot
    fig_para.axis_prop.xscale = 'log';
    fig_para.title.string = 'Semi-log';
    [ngph, ~, LH] = tile_graph(dat,fig_para, LH, ngph, FHoffset);
    
    %Log-log plot
    fig_para.axis_prop.xscale = 'log';fig_para.axis_prop.yscale = 'log';
    fig_para.title.string = 'Log-log';
    x_min = 10^floor(log10(min(dat.x(dat.y>0))));
    x_max = 10^ceil(log10(max(dat.x(dat.y>0))));
    fig_para.axis_prop.xlim = [x_min x_max];
    [ngph, FH, LH] = tile_graph(dat,fig_para, LH, ngph, FHoffset);
    
    %Spike count/R
    fig_para.axis_prop = struct([]);
    dat.y = dat.y./dat.x;
    fig_para.ylabel.string = 'Spike Count/R*';
    fig_para.title.string = 'Spike Count/R*';
    fig_para.axis_prop(1).xscale = 'linear';fig_para.axis_prop(1).yscale = 'linear';
    fig_para.line_prop.marker = 'o';
     [ngph, FH, LH] = tile_graph(dat,fig_para, @plot, ngph, FHoffset);

    %PSTH
    clear dat;fig_para.line_prop.marker ='none';
    idx_nonzero = cellfun(@(x)any(x>0),cur_node.PSTH.value);
    dat.x = cur_node.PSTH.xvalue(idx_nonzero); dat.y = cur_node.PSTH.value(idx_nonzero);
    dat.para = cur_node.RstarMean(idx_nonzero);
    dat.legend.string = cellstr(num2str(dat.para','%3.2g'));
    if OFFcell
        dat.legend.location = 'Southwest';
    else
        dat.legend.location = 'Northwest';
    end
    fig_para.axis_prop.xscale = 'linear';fig_para.axis_prop.yscale = 'linear';
    fig_para.title.string = 'PSTH';
    fig_para.xlabel.string = 'Time (sec)'; 
    fig_para.ylabel.string = 'Firing rate (Hz)';
    x_min = unique(cur_node.recordingOnset.value);x_max = unique(cur_node.recordingOffset.value);
    fig_para.axis_prop.xlim = [x_min x_max];
    [ngph, FH, LH] = tile_graph(dat,fig_para,@plot, ngph, FHoffset);
    
    %Smoothed PSTH
    clear dat;fig_para.line_prop.marker ='none';
    idx_nonzero = cellfun(@(x)any(x>0),PSTH_smth);
    dat.x = cur_node.PSTH.xvalue(idx_nonzero); dat.y = PSTH_smth(idx_nonzero);
    dat.para = cur_node.RstarMean(idx_nonzero);
    dat.legend.string = cellstr(num2str(dat.para','%3.2g'));
    if OFFcell
        dat.legend.location = 'Southwest';
    else
        dat.legend.location = 'Northwest';
    end
    fig_para.axis_prop.xscale = 'linear';fig_para.axis_prop.yscale = 'linear';
    fig_para.title.string = sprintf('PSTH %dpts smoothing',npt_smth);
    fig_para.xlabel.string = 'Time (sec)'; 
    fig_para.ylabel.string = 'Firing rate (Hz)';
    x_min = unique(cur_node.recordingOnset.value);x_max = unique(cur_node.recordingOffset.value);
    fig_para.axis_prop.xlim = [x_min x_max];
    [ngph, FH, LH] = tile_graph(dat,fig_para,@plot, ngph, FHoffset);
    
    %PSTH peak (baseline subtracted)
    dat.y = PSTH_baseline_subtracted;
    %PSTH/R
    idx = 1:length(dat.y);
    dat.y = arrayfun(@(n)dat.y{n}/dat.para(n),idx,'uniformoutput',false);
    fig_para.title.string = 'PSTH/R*';fig_para.ylabel.string = 'Firing rate/R* (Hz/R*)';
    [ngph, FH, LH] = tile_graph(dat,fig_para,@plot, ngph, FHoffset);
    
    %PSTH peak (baseline subtracted)
    dat.y = PSTH_baseline_subtracted_smoot;
    %PSTH/R
    idx = 1:length(dat.y);
    dat.y = arrayfun(@(n)dat.y{n}/dat.para(n),idx,'uniformoutput',false);
    fig_para.title.string = 'PSTH/R*';fig_para.ylabel.string = 'Firing rate/R* (Hz/R*)';
    [ngph, FH, LH] = tile_graph(dat,fig_para,@plot, ngph, FHoffset);
    
    
    %Peak value in abs(PSTH_subtacted)
    clear dat;
    fig_para.line_prop.marker ='o';
    dat.x = cur_node.RstarMean;
    dat.y = PSTH_abspeaks;
    
    fig_para.title.string = 'Peak firing rate';
    fig_para.xlabel.string = 'R*';
    fig_para.ylabel.string = 'Firing rate (Hz)';
    fig_para.axis_prop.xlim = [-Inf Inf];
    [ngph, FH, LH] = tile_graph(dat,fig_para,@plot, ngph, FHoffset);
    
    %Peak value log-log??
    fig_para.axis_prop.xscale = 'log';fig_para.axis_prop.yscale = 'log';
    fig_para.title.string = 'Peak firing rate log-log';
    x_min = 10^floor(log10(min(dat.x(dat.y>0)))); 
    x_max = 10^ceil(log10(max(dat.x(dat.y>0)))); 
    fig_para.axis_prop.xlim = [x_min x_max];
    [ngph, FH, LH] = tile_graph(dat,fig_para, LH, ngph, FHoffset);
    
    %Peak value sensitivity
    dat.y = dat.y./dat.x;
    fig_para.axis_prop.xscale = 'linear';fig_para.axis_prop.yscale = 'linear';
    fig_para.title.string = 'Peak firing rate/R*';
    fig_para.xlabel.string = 'R*';
    fig_para.ylabel.string = 'Firing rate/R* (Hz/R*)';
    fig_para.axis_prop.xlim = [-Inf Inf];
    [ngph, FH, LH] = tile_graph(dat,fig_para,@plot, ngph, FHoffset);
    
    
    
    
end


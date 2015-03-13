function acrossCellSummaryPlot()
    close all;
    %parameters
    nrow = 3; ncol = 4;
    fig_para = v2struct(nrow,ncol);
    global ANALYSIS_FOLDER
    save_path = fullfile(ANALYSIS_FOLDER,'SummaryPlots','AcrossCells');
    cellName_set = uigetfile([ANALYSIS_FOLDER,'analysisTrees' filesep],'MultiSelect','on');
    if ~iscell(cellName_set)
       cellName_set = {cellName_set}; 
    end
    % get cell types
    num_cell = length(cellName_set);
    cellType_all = cell(num_cell,1);
    for nc = 1:num_cell
        load(fullfile(ANALYSIS_FOLDER,'cellData', cellName_set{nc}));
        cellType_all{nc} = cellData.cellType;
    end
    [cellType_unique, ~, cell_idx] = unique(cellType_all);
    n_cellType = length(cellType_unique);
    % for across celltype analysis
    spc_perR_max = cell(n_cellType,1);
    %Set a loop for different stimuli??
    analysis_class = 'LightStep';
    stimulus_type = 'LightStep_20';
    for nt = 1:n_cellType
        celltype_name = cellType_unique{nt};
        if isempty(celltype_name)
            continue;
        end
        cnames_sametype = cellName_set(cell_idx==nt);
        n_cells_sametype = length(cnames_sametype);
        %Across cell analysis
        fig_para.annotation.string = [stimulus_type,' ',celltype_name];
        fig_para.ngph = 1;
        fig_para.FHoffset = 0;
        %Across cell-type analysis
        %tmp_spc_perR_max = zeros(n_cells_sametype,1);
        tmp_spc_perR_max = struct([]);
        for ncell = 1:length(cnames_sametype)
            fig_para.nTotalGraphs = 2*length(cnames_sametype);
            cellName = rm_ext(cnames_sametype{ncell});
            load([ANALYSIS_FOLDER 'analysisTrees' filesep cellName]);%analysisTree is loaded
            tr = analysisTree;
            load([ANALYSIS_FOLDER 'cellData' filesep cellName]);%cellData is loaded
            cdat = cellData;
            fig_para.title.string = cellName;
            %idx = find(tr.treefun(@(x)~isempty(strfind(x.name,analysis_class))));
            idx = find(tr.treefun(@(x)~isempty(strfind(x.name,stimulus_type))));
            if length(idx) > 1
                error('There should be only one DataSet with this name!');
            end
            %% Analysis over leaves (e.g. response vs R*, etc.) should be done here!
            cur_parent = tr.Node{idx};
            [FH, ngph,fig_para] = plot_spikecount( cur_parent, fig_para, celltype_name );
            [FH, ngph,fig_para, ~, max_val] = plot_spikecount_per_R( cur_parent, fig_para, celltype_name );
            tmp_spc_perR_max(ncell).cellname = cellName;
            tmp_spc_perR_max(ncell).x = max_val.x; 
            tmp_spc_perR_max(ncell).y = max_val.y;

        end
        %store meausred values for across cell-type analysis
        spc_perR_max{nt} = tmp_spc_perR_max
        sname = sprintf('%s_%s_SummaryPlot.pdf',stimulus_type, celltype_name);
        sname(isspace(sname))='_';
        sname = strrep(sname,'-/-','MM');
        sname = strrep(sname,'+/+','PP');
        %sname = 'test.pdf';
        setFigureSize( );
        save_figs('', sname,save_path,'saveas');
    end
    %% Do across cell-type analysis here!
    splitter = {'on alpha','off sustained alpha','off transient alpha'};
    clear fig_para;
    fig_para.ncol = 3; fig_para.nrow = 2;
    fig_para.FHoffset = 0; fig_para.ngph = 1;
    fig_para.nTotalGraphs = 3;fig_para.annotation.string = stimulus_type;
    % Plot spike count/R* max vs
    fig_para.axis_prop.xscale = 'log';fig_para.axis_prop.yscale = 'log';
    fig_para.xlabel.string = 'R*@max';fig_para.ylabel.string = 'max(SPC/R*)';
    [FH, fig_para] = plot_across_celltype(spc_perR_max, cellType_unique, fig_para, splitter);
    %when needed add another with different variables
    sname = [stimulus_type,'_AcrossCelltypeSummary.pdf'];
    setFigureSize();
    save_figs('',sname,save_path,'saveas');
end
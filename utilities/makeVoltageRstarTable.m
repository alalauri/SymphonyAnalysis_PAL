function epochs = makeVoltageRstarTable( )
%Add LED pulse and bakcground voltages to Symphony data (only those with
%old version)
    %% Test purpose
    if nargin == 0
        clear; close all;
        load('/Users/dtakeshi/Documents/Data/RigA/testfiles/LEDFactorPulse_TestEpochs.mat');%s is loaded
        epochs = s.epochs;%epochs is an array of EpochData instances
        rig_name = 'a'; 
        exp_date = [2015, 1, 27];
        NDFs = {'4a','2a'};
        t_stim_set = [20 500 5000];
        ch_LED_set ={'Ch1'};
        vol = 1000*2.^(-5:3)-10;%[31.25 62.5 ... 1000 ... 8000]mV
    else
        [rig_name, exp_date] = fname2info( file_name );
    end
    %% function main
    %read NDFs
%     [t_NDF, NDFs] = readNDF_log(rig_name, exp_date);
    %OD_list = readNDFcalibration();%ODs are hard-coded in NDF_ODlist
    % Load linearity correction table
%     t_stim_set = unique(get2(epochs,'stimTime'));
%     ch_LED_set = unique(get2(epochs,'StimulusLED'));
    tableMap = readLinearityCorrection(rig_name, ch_LED_set, t_stim_set);
    tableKeys = keys(tableMap);
    % Do!!--Get reference voltage & intensity and calculate R* value!!
    I = readIntensityMeasurement( exp_date );
    Rstar_ref = intensity2Rstar(I.Power, (I.DiameterX+I.DiameterY)/2);
    Vref = I.Voltage;
    nNDFset = size(NDFs,1);
    for n=1:nNDFset
        for nk = 1:length(tableKeys)
            table_key = tableKeys{nk};
            %t_data = epochs(n).attributes('inputTime');
            %namesNDF = getNDFnames(t_data, t_NDF, NDFs);
            namesNDF = NDFs(n,:);
            trans = getTransmittance(namesNDF,rig_name);
            %ch_LED = epochs(n).attributes('StimulusLED');
            %vol = epochs(n).attributes('pulseAmplitude');
            %t_stim = epochs(n).attributes('stimTime');
            %table_key = sprintf('%s-%dms',ch_LED,t_stim);
            t_stim = str2double(pick_str(table_key,'-','ms',1,1));
            table = tableMap(table_key);
            %Calculate R*
            Rstar_sec = Rstar_ref * getCvalue(table.Voltage,table.Mean,vol)...
                /getCvalue(table.Voltage, table.Mean, Vref)*trans;
            Rstar = Rstar_sec*t_stim/1000;
            if isnan(Rstar)
                2;
            end
            %epochs(n).attributes('RstarMean')=Rstar;
            %Store information about R* calculation
            info_tmp.NDFs = namesNDF;info_tmp.NDF_OD = -log10(trans);
            info_tmp.Linearity = table;
            %epochs(n).attributes('NDFs') = namesNDF;
            %epochs(n).attributes('NDF_OD') = -log10(trans);
            %epochs(n).attributes('LinearityCorrection') = table.fname;
        end
    end
end

function Cq = getCvalue(V,C,Vq)
    if Vq >= V(1)
        Cq = interp1(V,C,Vq);
    else
        Cq = C(1)*Vq/V(1);%linearly interpolate btw V(1) & 0
    end
end

function namesNDF = getNDFnames(t_data, t_NDF, NDFs)
    t_data = datenum(t_data)-floor(datenum(t_data));
    idx = find(t_data > t_NDF,1,'last');
    nNDFs = size(NDFs,2);
    if isempty(idx)
        namesNDF = '';
    else
        namesNDF = NDFs(idx,:);
    end
end

function out = create(epochs)
    list_properties = {'LEDbackground','StimulusLED','displayName','initialPulseAmplitude',...
             'numberOfIntensities','numberOfRepeats',...
             'preTime','scalingFactor','stimTime','tailTime'};
    vals = cell( list_properties);
    for n=1:length(list_properties)
        props = get2(epochs, list_properties{n});
        if ~is_allequal(props);
            error(['Dividing into epoch groups is not correctly done!'])
        else
            if iscell(props)
                vals{n} = props{1};
            else
                vals{n} =  unique(props);
            end
        end
    end
    out = cell2struct(vals, list_properties,2);
end

function out = is_allequal(v)
    if iscell(v) 
        if ischar(v{1})
            out = all(strcmp(v(:),v(1)));
        elseif isnumeric(v{1})
            out = all(cellfun(@(x)all(eq(x,v{1})),v,'uniformoutput',true));
        end
    elseif isnumeric(v)
        out = all(v(:)==v(1));
    else
        out = false;
    end
end

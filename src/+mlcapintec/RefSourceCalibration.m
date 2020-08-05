classdef RefSourceCalibration < handle & mlpet.AbstractCalibration
	%% REFSOURCECALIBRATION  

	%  $Revision$
 	%  was created 06-Nov-2018 14:56:50 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)        
        BEST_DATETIME = datetime(2017,9,6)
        Na22_PREDICTED_MINUS_Na22_MEASURED = 0.658878 % kdpm, from [22Na] reference source
        Ge68_PREDICTED_OVER_Ge68_MEASURED = 0.979873 % from [68Ge] reference source

        FILENAME = 'CCIRRadMeasurements 2018oct5.xlsx'  % 68Ge, 22Na, 137Cs        
       %FILENAME = 'CCIRRadMeasurements 2018sep12.xlsx' % 22Na
    end

    properties (Dependent)
        activity
        calibrationAvailable
        invEfficiency
        refSource
    end
    
    methods (Static)
        function mat = buildCalibration()
            mat = [];
        end   
        function this = createFromSession(varargin)
            %% CREATEBYSESSION
            %  @param required sessionData is an mlpipeline.ISessionData.
            %  See also:  mlpet.CCIRRadMeasurements.createFromSession().
            
            rad = mlpet.CCIRRadMeasurements.createFromSession(varargin{:}, 'exactMatch', false);
            this = mlcapintec.RefSourceCalibration.createFromRadMeasurements(rad);
        end
        function this = createFromRadMeasurements(rad)
            %% CREATEBYRADMEASUREMENTS
 			%  @param required radMeasurements is mlpet.CCIRRadMeasurements.

            assert(isa(rad, 'mlpet.CCIRRadMeasurements'))
            this = mlcapintec.RefSourceCalibration(rad);
        end      
        function inveff = invEfficiencyf()
            inveff = mlcapintec.RefSourceCalibration.Ge68_PREDICTED_OVER_Ge68_MEASURED;
        end
        function [activityMeas,activityPred] = plot_datetime2RefSourceDeviation(ref, rms)
            %% PLOT_DATETIME2REFSOURCEDEVIATION
            %  @param ref is mlpet.ReferenceSource
            %  @param rms is {mlpet.CCIRRadMeasurements}.
            %  @return activityMeas, activityPred are numeric.            
            
            tra = sprintf('[%s]', ref.isotope);
            datetimeMeas = [];
            activityMeas = [];
            activityPred = [];
            fileprefixes = {};
            for r = rms
                ccir = r{1};
                wc = ccir.wellCounter;
                time = wc.TIMECOUNTED_Hh_mm_ss(strcmp(wc.TRACER, tra));
                time = time(~isnat(time));
                if lstrfind(lower(tra), 'cs')
                    meas = wc.CF_Kdpm(strcmp(wc.TRACER, tra));
                else
                    meas = wc.Ge_68_Kdpm(strcmp(wc.TRACER, tra));
                end
                meas = meas(~isnan(meas));
                pred = ref.predictedActivity(datetime(ccir), 'kdpm')*ones(size(meas));
                datetimeMeas = [datetimeMeas; time];
                activityMeas = [activityMeas; meas]; %#ok<*AGROW>
                activityPred = [activityPred; pred];
                fileprefixes = [fileprefixes; repmat({ccir.fileprefix}, size(meas))];
            end
            
            figure
            plot(datetimeMeas, activityMeas - activityPred, ':o')
            title(sprintf('[%s] ref source measurement stability on Caprac over time', ref.isotope))
            xlabel('datetime')
            ylabel('(measured activity - predicted activity) / kdpm')
           
            for i = 1:length(datetimeMeas)
                fprintf('datetime -> %s\t fileprefix -> %s\t meas - pred -> %g kdpm\t meas/pred -> %g\n', ...
                    datetimeMeas(i), fileprefixes{i}, activityMeas(i) - activityPred(i), activityMeas(i)/activityPred(i))
            end
            
            fprintf('mean([activityMeas   activityPred]) -> %g kdpm\n', mean([activityMeas'   activityPred']))
            fprintf('mean( activityMeas - activityPred ) -> %g kdpm\n', mean( activityMeas -  activityPred  ))
            fprintf(' std( activityMeas - activityPred ) -> %g kdpm\n',  std( activityMeas -  activityPred  ))
            fprintf('mean( activityMeas / activityPred ) -> %g     \n', mean( activityMeas ./ activityPred  ))
            fprintf(' std( activityMeas / activityPred ) -> %g     \n',  std( activityMeas ./ activityPred  ))
            fprintf('                                  N -> %i\n',    length( activityMeas))
            fprintf('                           duration -> %g\n',      days(max(datetimeMeas) - min(datetimeMeas)))
        end
        function [activityMeas,activityPred] = plotRefSourceStability(isotope)
            %% PLOTREFSOURCESTABILITY:
            %  ref measurement datetimes are enumerated in file 'cross-calibrations_20190817.xlsx'
            %  @param isotope is char.
            %  @return activityMeas, activityPred are numeric.
            
            import mlpet.ReferenceSource            
            tz = 'America/Chicago';
            switch isotope
                case '137Cs'
                    ref = ReferenceSource( ...
                        'isotope', '137Cs', ...
                        'activity', 500, ...
                        'activityUnits', 'nCi', ...
                        'sourceId', '1231-8-87', ...
                        'refDate', datetime(2007,4,1, 'TimeZone', tz));                   
                case '22Na'
                    ref = ReferenceSource( ...
                        'isotope', '22Na', ...
                        'activity', 101.4, ...
                        'activityUnits', 'nCi', ...
                        'sourceId', '1382-54-1', ...
                        'refDate', datetime(2009,8,1, 'TimeZone', tz));
                case '68Ge'
                    ref = ReferenceSource( ...
                        'isotope', '68Ge', ...
                        'activity', 101.3, ...
                        'activityUnits', 'nCi', ...
                        'sourceId', '1932-53', ...
                        'refDate', datetime(2017,11,1, 'TimeZone', tz), ...
                        'productCode', 'MGF-068-R3');
                otherwise
                    error('mlcapintec:NotImplementedError', ...
                        'CapracCalibration.plotRefSourceStability.isotope->%s', isotope)
            end            
            rms = {};
            for g = globT(fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'CCIRRadMeasurements*.xlsx'))
                rm = mlpet.CCIRRadMeasurements.createFromFilename(g{1});
                if lstrfind(rm.wellCounter.TRACER, isotope) && all(~isnan(rm.wellCounter.CF_Kdpm))
                    rms = [rms {rm}];
                end
            end            
                        
            [activityMeas,activityPred] = mlcapintec.RefSourceCalibration.plot_datetime2RefSourceDeviation(ref, rms);
        end
    end
    
	methods 
        
        %% GET 
        
        function g = get.activity(this)
            switch (this.refSource.isotope)
                case {'68Ge' '22Na'}
                    g = this.radMeasurements.wellCounter.Ge_68_Kdpm * (1e3/60); % Bq
                case '137Cs'
                    g = this.radMeasurements.wellCounter.CF_Kdpm * (1e3/60); % Bq
                otherwise
                    error('mlcapintec:ValueError', 'RefSourceCalibration.get.activity for %s', this.refSource.isotope);
            end
        end
        function g = get.calibrationAvailable(~)
            g = true;
        end
        function g = get.invEfficiency(~)
            g = mlcapintec.RefSourcCalibration.invEfficiencyf();
        end
        function g = get.refSource(this)
            g = this.refSource_;
        end
        
        %%
		  
 		function this = RefSourceCalibration(varargin)
 			%% REFSOURCECALIBRATION
 			%  @param isotope \in {'[68Ge]' '[22Na]' '[137Cs]'}.

 			this = this@mlpet.AbstractCalibration(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'radMeas', @(x) isa(x, 'mlpet.RadMeasurements'));
            addParameter(ip, 'refSource', [], @(x) isa(x, 'mlpet.ReferenceSource'));
            parse(ip, varargin{:});  
            this.refSource_ = ip.Results.refSource;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        refSource_
        tableCache_
    end
    
    %% HIDDEN, DEPRECATED
    
    methods (Hidden, Static)
        function [this,h1,h2] = screenInvEfficiencies(varargin)
            %  @param filepath is dir;  default := getenv('CCIR_RAD_MEASUREMENTS_DIR').
 			%  @param refSource is mlpet.ReferenceSource.
            %  @param makeplot is logical.
            %  @param trainmodel is logical.
            %  @return this is the RefSourceCalibration.
            %  @return h1, h2 are figure handles to plots from "activity" to "predicted activity" and "efficiency^{-1}".
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'filepath', getenv('CCIR_RAD_MEASUREMENTS_DIR'), @isfolder);
            addParameter(ip, 'makeplot', false, @islogical);
            addParameter(ip, 'trainmodel', false, @islogical);
            parse(ip);
            
            xlsx = mlsystem.DirTool(fullfile(ip.Results.filepath, 'CCIRRadMeasurements*.xlsx'));
            tbl  = [];
            for x = 1:length(xlsx.fqfns)
                try
                    radMeas_ = mlpet.CCIRRadMeasurements.createFromFilename(fullfile(ip.Results.filepath, xlsx.fns{x}));
                    this_ = mlcapintec.RefSourceCalibration(radMeas_, varargin{:});
                    tbl = vertcat(tbl, table(this_));
                catch ME
                    dispwarning(ME);
                end
            end                
            this_.tableCache_ = tbl;        
            this = this_;
            
            disp(tbl);
            h1   = [];
            h2   = [];
            if (ip.Results.makeplot)
                h1 = figure;
                plot(tbl.activity, tbl.predActivity, 'o', 'LineStyle', 'none');
                xlabel('activity / Bq');
                ylabel('predicted activity / Bq');
                h2 = figure;
                plot(tbl.activity, tbl.invEfficiency, 'o', 'LineStyle', 'none');
                xlabel('activity / Bq');
                ylabel('efficiency^{-1}');
            end
            fprintf('invEfficiency %s:  mean -> %g, std -> %g\n', this.refSource.isotope, mean(tbl.invEfficiency), std(tbl.invEfficiency));
            if (ip.Results.trainmodel && isempty(this.trainedModelInvEff_))
                this.trainedModelInvEff_ = this.trainModelInvEff;
            end     
        end
        function [this,h1,h2] = screenInvEfficiency(varargin)
            %  @param filepath is dir;  default := getenv('CCIR_RAD_MEASUREMENTS_DIR').
            %  @param filename is char; default := 'CCIRRadMeasurements 2018oct5.xlsx'.
 			%  @param refSource is mlpet.ReferenceSource.
            %  @param makeplot is logical.
            %  @param trainmodel is logical.
            %  @return call this.trainModelInvEff if trainmodel and this.trainedModelInvEff is empty.
            %  @return this is the RefSourceCalibration.
            %  @return h1, h2 are figure handles to plots from "activity" to "predicted activity" and "efficiency^{-1}".
            
            import mlcapintec.RefSourceCalibration;
            ip = inputParser;
            addParameter(ip, 'date', RefSourceCalibration.BEST_DATETIME, @ischar);
            addParameter(ip, 'makeplot', true, @islogical);
            addParameter(ip, 'trainmodel', false, @islogical);
            parse(ip);
            radMeas = mlpet.CCIRRadMeasurements.createFromDate(ip.Results.date);
            this = RefSourceCalibration('radMeas', radMeas, varargin{:});            
            tbl = table(this);  
            
            disp(tbl);
            h1 = []; 
            h2 = [];
            if (ip.Results.makeplot)
                h1 = figure;
                plot(tbl.activity, tbl.predActivity, 'o', 'LineStyle', 'none');
                xlabel('activity / Bq');
                ylabel('predicted activity / Bq');
                h2 = figure;
                plot(tbl.activity, tbl.invEfficiency, 'o', 'LineStyle', 'none');
                xlabel('activity / Bq');
                ylabel('efficiency^{-1}');
            end           
            fprintf('invEfficiency %s:  mean -> %g, std -> %g\n', this.refSource.isotope, mean(tbl.invEfficiency), std(tbl.invEfficiency)); 
            if (ip.Results.trainmodel && isempty(this.trainedModelInvEff_))
                this.trainedModelInvEff_ = this.trainModelInvEff;
            end
        end
    end
    
    methods (Hidden) 
        function g = getTrainedModelInvEff__(this)
            %  invEfficiency 137Cs:  mean -> 1.20775,  std -> 0.00341237
            %  invEfficiency 22Na:   mean -> 1.02843,  std -> 0.019226
            %  invEfficiency 68Ge:   mean -> 0.978943, std -> 0.00854864
            
            switch (this.refSource_.isotope)
                case '68Ge'
                    g = 0.978943;
                case '22Na'
                    g = 1.02843 * (0.970955/1.03063);
                case '137Cs'  
                    g = 1.20775 * (0.970955/1.20462);
                otherwise
                    error('mlcapintec:ValueError', 'RefSourceCalibration.get.trainedModelInvEff');
            end
        end
        function g = getTrainedModelInvEff_mat__(~)
            g = fullfile( ...
                mlpipeline.ResourcesRegistry.instance().matlabDrive, ...
                'mlcapintec', 'src', '+mlcapintec', 'trainedModelInvEffRefSource.mat');
        end        
        function tbl = table(this, varargin)
            %% TABLE
            %  @return table(..., 'VariableNames', {'volume' 'activity' 'predActivity' 'invEfficiency'}, varargin{:})
            %  for decaying activity and invEfficiency := activity / predActivity; 
            
            if (~isempty(this.tableCache_))
                tbl = this.tableCache_;
                return
            end
            if (isempty(this.refSource))
                tbl = [];
                return
            end
            
            import mlcapintec.RefSourceCalibration;
            import mlpet.Radionuclides.halflifeOf;
            tr  = this.radMeasurements.wellCounter.TRACER;
            sel = strcmp(tr, sprintf('[%s]', this.refSource.isotope));
            
            t   = this.radMeasurements.wellCounter.TIMECOUNTED_Hh_mm_ss(sel); % datetime
            a   = this.activity(sel); % Bq            
            pa  = this.refSource.predictedActivity(t, 'Bq'); % Bq, decay-adjusted
            ie  = pa ./ a;
            assert(all(~isnan(ie)), 'mlcapintec:ValueError', 'RefSourceCalibration.table');            
            tbl = table(t, a, pa, ie, 'VariableNames', {'datetime' 'activity' 'predActivity' 'invEfficiency'}, varargin{:});
        end 
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


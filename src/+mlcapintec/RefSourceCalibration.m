classdef RefSourceCalibration < mlcapintec.CapracCalibration
	%% REFSOURCECALIBRATION  

	%  $Revision$
 	%  was created 06-Nov-2018 14:56:50 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
       %FILENAME = 'CCIRRadMeasurements 2018sep12.xlsx' % 22Na
        FILENAME = 'CCIRRadMeasurements 2018oct5.xlsx' % 68Ge, 22N, 137Cs
    end

    properties (Dependent)
        activity
        refSource
        trainedModelInvEff
        trainedModelInvEff_mat % mat-filename
    end
    
    methods (Static)
        function [this,h1,h2] = screenInvEfficiencies(varargin)
            %  @param filepath is dir;  default := getenv('CCIR_RAD_MEASUREMENTS_DIR').
 			%  @param refSource is mlpet.ReferenceSource.
            %  @param makeplot is logical.
            %  @param trainmodel is logical.
            %  @return this is the RefSourceCalibration.
            %  @return h1, h2 are figure handles to plots from "activity" to "predicted activity" and "efficiency^{-1}".
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'filepath', getenv('CCIR_RAD_MEASUREMENTS_DIR'), @isdir);
            addParameter(ip, 'makeplot', true, @islogical);
            addParameter(ip, 'trainmodel', false, @islogical);
            parse(ip);
            
            xlsx = mlsystem.DirTool(fullfile(ip.Results.filepath, 'CCIRRadMeasurements*.xlsx'));
            tbl  = [];
            import mlcapintec.RefSourceCalibration;
            for x = 1:length(xlsx.fqfns)
                this_ = RefSourceCalibration(varargin{:}, 'filepath', ip.Results.filepath, 'filename', xlsx.fns{x});
                tbl = vertcat(tbl, table(this_)); %#ok<AGROW>
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
            addParameter(ip, 'filename', RefSourceCalibration.FILENAME, @ischar);
            addParameter(ip, 'makeplot', true, @islogical);
            addParameter(ip, 'trainmodel', false, @islogical);
            parse(ip);
            this = RefSourceCalibration('filename', ip.Results.filename, varargin{:});            
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
    
	methods 
        
        %% GET        
        
        function g = get.activity(this)
            switch (this.refSource.isotope)
                case {'68Ge' '22Na'}
                    g = this.wellCounter.Ge_68_Kdpm * (1e3/60); % Bq
                case '137Cs'
                    g = this.wellCounter.CF_Kdpm * (1e3/60); % Bq
                otherwise
                    error('mlcapintec:ValueError', 'RefSourceCalibration.get.activity for %s', this.refSource.isotope);
            end
        end
        function g = get.refSource(this)
            g = this.refSource_;
        end
        function g = get.trainedModelInvEff(this)
            %  invEfficiency 137Cs:  mean -> 1.20719,  std -> 0.00351095
            %  invEfficiency 22Na:   mean -> 1.02843,  std -> 0.019226
            %  invEfficiency 68Ge:   mean -> 0.978943, std -> 0.00854864
            
            switch (this.refSource_.isotope)
                case '68Ge'
                    g = 0.978943;
                case '22Na'
                    g = 1.02843 * (0.970955/1.03063);
                case '137Cs'  
                    g = 1.20719 * (0.970955/1.20462);
                otherwise
                    error('mlcapintec:ValueError', 'RefSourceCalibration.get.trainedModelInvEff');
            end
        end
        function g = get.trainedModelInvEff_mat(~)
            g = fullfile( ...
                mlpet.Resources.instance.matlabDrive, ...
                'mlcapintec', 'src', '+mlcapintec', 'trainedModelInvEffRefSource.mat');
        end
        
        %%
        
        function tbl  = table(this, varargin)
            %% TABLE
            %  @return table(..., 'VariableNames', {'volume' 'activity' 'predActivity' 'invEfficiency'}, varargin{:})
            %  for decaying activity and invEfficiency := activity / predActivity; 
            
            if (~isempty(this.tableCache_))
                tbl = this.tableCache_;
                return
            end
            
            import mlcapintec.RefSourceCalibration;
            import mlpet.Radionuclides.halflifeOf;
            tr  = this.wellCounter.TRACER;
            sel = strcmp(tr, sprintf('[%s]', this.refSource.isotope));
            if (isempty(sel))
                tbl = [];
                return
            end
            
            t   = this.wellCounter.TIMECOUNTED_Hh_mm_ss(sel); % datetime
            a   = this.activity(sel); % Bq            
            pa  = this.refSource.predictedActivity(t, 'Bq'); % Bq, decay-adjusted
            ie  = pa ./ a;
            assert(all(~isnan(ie)), 'mlcapintec:ValueError', 'RefSourceCalibration.table');            
            tbl = table(t, a, pa, ie, 'VariableNames', {'datetime' 'activity' 'predActivity' 'invEfficiency'}, varargin{:});
        end
		  
 		function this = RefSourceCalibration(varargin)
 			%% REFSOURCECALIBRATION
 			%  @param isotope \in {'[68Ge]' '[22Na]' '[137Cs]'}.

 			this = this@mlcapintec.CapracCalibration(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'refSource', [], @(x) isa(x, 'mlpet.ReferenceSource'));
            parse(ip, varargin{:});  
            this.refSource_ = ip.Results.refSource;
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)
        function [trainedModel, validationRMSE] = trainRegressionLearner__(~, varargin)
            trainedModel = [];
            validationRMSE = [];
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        refSource_
        tableCache_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


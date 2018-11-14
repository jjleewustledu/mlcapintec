classdef CapracCalibration < handle & matlab.mixin.Heterogeneous
	%% CAPRACCALIBRATION  

	%  $Revision$
 	%  was created 06-Nov-2018 14:46:31 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
        WATER_DENSITY = 0.9982 % pure water at 20 C := 0.9982 mL/g; tap := 0.99823
    end
    
    properties (Dependent)
        alpha
        wellCounter
    end

	methods 
        
        %% GET
        
        function g = get.alpha(~)
            g = mlpet.Resources.instance.alpha;
        end
        function g = get.wellCounter(this)
            g = this.radMeasurements_.wellCounter;
        end
        
        %%
        
        function ie   = predictInvEff(this, varargin)
            %% PREDICTINVEFF predicts efficiency^{-1} from sample volumes.
            %  @param volume is table || is numeric.
            %  @return ie is numeric.
            
            ip = inputParser;
            addRequired(ip, 'volume', @(x) istable(x) || isnumeric(x));
            parse(ip, varargin{:});
            volume = ip.Results.volume;
            
            if (isnumeric(volume))
                volume = ensureColVector(volume);
                volume = table(volume);
            end
            assert(istable(volume));
            assert(~isempty(this.trainedModelInvEff));
            ie = this.trainedModelInvEff.predictFcn(volume);
        end
        function trainedModel = trainModelInvEff(this)
            %% TRAINMODELINVEFF trains as needed a de novo model using Quadratic SVM, which has historically worked well 
            %  for CapracCalibration subclasses.  If a previous model has been serialized in mat-file
            %  this.trainedModelInvEff_mat, TRAINMODELINVEFF imports that model.
            %  To explore training possibilities see also:  web(fullfile(docroot, 'stats/regressionlearner-app.html')).

            if (~lexist(this.trainedModelInvEff_mat, 'file'))                
                trainedModel = this.trainRegressionLearner__(table(this));
                save(this.trainedModelInvEff_mat, 'trainedModel');
                return
            end
            
            load(this.trainedModelInvEff_mat, 'trainedModel');
            assert(isstruct(trainedModel)); %#ok<NODEF>
            assert(isa(trainedModel.predictFcn, 'function_handle'));
            assert(strcmp(trainedModel.About, ...
                'This struct is a trained model exported from Regression Learner R2018a.'));
        end
		  
 		function this = CapracCalibration(varargin)
 			%% CAPRACCALIBRATION
            %  @param filepath for CCIRRadMeasurements; default := getenv('CCIR_RAD_MEASUREMENTS_DIR').
 			%  @param filename for CCIRRadMeasurements; default := ''.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'filepath', getenv('CCIR_RAD_MEASUREMENTS_DIR'), @isdir);
            addParameter(ip, 'filename', '', @ischar);
            parse(ip, varargin{:});            
            this.radMeasurements_ = mlpet.CCIRRadMeasurements.CreateByFilename( ...
                fullfile(ip.Results.filepath, ip.Results.filename), 'alwaysUseSessionDate', false);
            %this.trainedModelInvEff_ = this.trainModelInvEff;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        radMeasurements_
        trainedModelInvEff_
    end
    
    methods (Access = protected)
        function [trainedModel, validationRMSE] = trainRegressionLearner__(~, varargin)
            trainedModel = [];
            validationRMSE = [];
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


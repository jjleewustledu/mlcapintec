classdef (Abstract) AbstractCalibration < handle & matlab.mixin.Heterogeneous
	%% ABSTRACTCALIBRATION  

	%  $Revision$
 	%  was created 20-Dec-2018 14:45:02 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	 	
	properties (Constant)
        WATER_DENSITY = 0.9982 % pure water at 20 C := 0.9982 mL/g; tap := 0.99823
        BLOOD_DENSITY = 1.06 % https://hypertextbook.com/facts/2004/MichaelShmukler.shtml; human whole blood 37 C
        BRAIN_DENSITY = 1.05 % Torack et al., 1976
        PLASMA_DENSITY = 1.03
    end
    
    properties (Dependent)
        alpha % for significance
        trainedModelInvEff % from regressionLearner
        trainedModelInvEff_mat % mat-filename
        wellCounter 
    end

	methods 
        
        %% GET
        
        function g = get.alpha(~)
            g = mlpipeline.ResourcesRegistry.instance().alpha;
        end
        function g = get.trainedModelInvEff(this)
            g = this.getTrainedModelInvEff__();
        end
        function g = get.trainedModelInvEff_mat(this)
            g = this.getTrainedModelInvEff_mat__();
        end
        function g = get.wellCounter(this)
            g = this.radMeasurements_.wellCounter;
        end
        
        %%
        
        function trainedModel = trainModelInvEff(this)
            %% TRAINMODELINVEFF trains as needed a de novo models which have historically worked well 
            %  for AbstractCalibration subclasses.  If a previous model has been serialized in mat-file
            %  this.trainedModelInvEff_mat, TRAINMODELINVEFF imports that model.
            %  To explore training possibilities see also:  web(fullfile(docroot, 'stats/regressionlearner-app.html')).

            if (~lexist(this.trainedModelInvEff_mat, 'file'))                
                trainedModel = this.trainRegressionLearner__(table(this));
                save(this.trainedModelInvEff_mat, 'trainedModel');
                return
            end
            
            load(this.trainedModelInvEff_mat, 'trainedModel');
            assert(isstruct(trainedModel)); 
            assert(isa(trainedModel.predictFcn, 'function_handle'));
            assert(strcmp(trainedModel.About, ...
                'This struct is a trained model exported from Regression Learner R2018a.'));
        end
		  
 		function this = AbstractCalibration(varargin)
 			%% ABSTRACTCALIBRATION
            %  @param required radMeas is mlpet.RadMeasurements.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'radMeas', @(x) isa(x, 'mlpet.RadMeasurements'));
            parse(ip, varargin{:});            
            this.radMeasurements_ = ip.Results.radMeas; 			
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        calibrator_
        radMeasurements_
    end
    
    methods (Access = protected)        
        function g = getTrainedModelInvEff__(this)
            obj = this.getTrainedModelInvEff_mat__;
            g = obj.trainedModelInveff;
        end
        function g = getTrainedModelInvEff_mat__(~)
            g = '';
        end
        function [trainedModel, validationRMSE] = trainRegressionLearner__(~, varargin)
            trainedModel = []; %#ok<NASGU>
            validationRMSE = []; %#ok<NASGU>
            error('mlcapintec:NotImplementedError', 'AbstractCalibration.trainRegressionLearner__')
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

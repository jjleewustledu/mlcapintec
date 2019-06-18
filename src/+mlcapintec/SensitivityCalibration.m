classdef SensitivityCalibration < handle & mlpet.AbstractCalibration
	%% SENSITIVITYCALIBRATION  

	%  $Revision$
 	%  was created 06-Nov-2018 14:57:03 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
 		BEST_ACTIVITY = 1e6/60 % Bq
        FILENAME = 'CCIRRadMeasurements 2017sep6.xlsx'
    end
    
    properties (Dependent)
        indexBestActivity
    end
    
    methods (Static)
        function [this,h1,h2] = screenInvEfficiency()
            %% displays a table of voluem, activity, predicted activity and efficiency^{-1}, and plots thereof.
            %  @return call this.trainModelInvEff if this.trainedModelInvEff is empty.
            %  @return this is the SensitivityCalibration.
            %  @return h1, h2 are figure handles to plots from "activity" to "predicted activity" and "efficiency^{-1}".
            
            radMeas = mlpet.CCIRRadMeasurements.createByDate(datetime(2017,9,6));
            this = mlcapintec.SensitivityCalibration(radMeas);
            tbl = table(this);
            
            disp(tbl);
            h1 = figure;
            plot(tbl.activity, tbl.predActivity, 'o', 'LineStyle', 'none');
            xlabel('activity / Bq');
            ylabel('predicted activity / Bq');
            h2 = figure;
            plot(tbl.activity, tbl.invEfficiency, 'o', 'LineStyle', 'none');
            xlabel('activity / Bq');
            ylabel('efficiency^{-1}');
            
            this.selfCalibrate;
        end
    end
    
	methods
        function g = get.indexBestActivity(this)
            if (isempty(this.indexBestActivity_))                
                da = this.wellCounter.Ge_68_Kdpm * (1e3/60) - this.BEST_ACTIVITY; % Bq
                [~,this.indexBestActivity_] = min(abs(da));
            end
            g = this.indexBestActivity_;
        end
        
        %%
        
        function ie   = predictInvEff(this, varargin)
            %% PREDICTINVEFF predicts efficiency^{-1} from activity in Bq.
            %  @param activies is table || is numeric.
            %  @return ie is numeric.
            
            ip = inputParser;
            addParameter(ip, 'activity', @(x) istable(x) || isnumeric(x));
            parse(ip, varargin{:});
            a = ip.Results.activity;
            
            if (isnumeric(a))
                a = ensureColVector(a);
                a = table(a, 'VariableNames', {'activity'});
            end
            assert(istable(a));
            assert(~isempty(this.trainedModelInvEff));
            ie = this.trainedModelInvEff.predictFcn(a) ./ a.activity;
            ie(ie < 0) = 0;
        end
        function tbl  = table(this, varargin)
            %% TABLE
            %  @return table(..., 'VariableNames', {'volume' 'activity' 'predActivity' 'invEfficiency'}, varargin{:})
            %  for decaying activity and invEfficiency := activity / predActivity; 
            
            import mlcapintec.SensitivityCalibration;
            import mlpet.Radionuclides.halflifeOf;
            v  = this.wellCounter.MassSample_G / SensitivityCalibration.WATER_DENSITY; % mL
            t  = this.wellCounter.TIMECOUNTED_Hh_mm_ss; % datetime
            a  = this.wellCounter.Ge_68_Kdpm * (1e3/60); % Bq
            hl = seconds(halflifeOf('[18F]')); % duration            
            
            vbest = v(this.indexBestActivity);
            abest = a(this.indexBestActivity);
            tbest = t(this.indexBestActivity); % datetime
            pa = (v/vbest) .* abest .* 2.^((tbest - t)/hl); % Bq, decay-adjusted
            ie = pa ./ a;
            assert(all(~isnan(ie)), 'mlcapintec:ValueError', 'SensitivityCalibration.table');
            
            % stabilize very low activity using prediction 0 -> 0 with ie := 1
            tbl = table([v;v(end)], [a;0], [pa;0], [ie;1], 'VariableNames', {'volume' 'activity' 'predActivity' 'invEfficiency'}, varargin{:});
        end
        
 		function this = SensitivityCalibration(varargin)
 			%% SENSITIVITYCALIBRATION
 			%  @param .

 			this = this@mlpet.AbstractCalibration(varargin{:});
 		end
    end
    
    %% PROTECTED
    
    methods (Access = protected)
        function g = getTrainedModelInvEff_mat__(~)
            g = fullfile( ...
                mlpipeline.ResourcesRegistry.instance().matlabDrive, ...
                'mlcapintec', 'src', '+mlcapintec', 'trainedModelInvEffSensitivity.mat');
        end
        function [trainedModel, validationRMSE] = trainRegressionLearner__(~, trainingData)
            % [trainedModel, validationRMSE] = trainRegressionModel(trainingData)
            % returns a trained regression model and its RMSE. This code recreates the
            % model trained in Regression Learner app. Use the generated code to
            % automate training the same model with new data, or to learn how to
            % programmatically train models.
            %
            %  Input:
            %      trainingData: a table containing the same predictor and response
            %       columns as imported into the app.
            %
            %  Output:
            %      trainedModel: a struct containing the trained regression model. The
            %       struct contains various fields with information about the trained
            %       model.
            %
            %      trainedModel.predictFcn: a function to make predictions on new data.
            %
            %      validationRMSE: a double containing the RMSE. In the app, the
            %       History list displays the RMSE for each model.
            %
            % Use the code to train the model with new data. To retrain your model,
            % call the function from the command line with your original data or new
            % data as the input argument trainingData.
            %
            % For example, to retrain a regression model trained with the original data
            % set T, enter:
            %   [trainedModel, validationRMSE] = trainRegressionModel(T)
            %
            % To make predictions with the returned 'trainedModel' on new data T2, use
            %   yfit = trainedModel.predictFcn(T2)
            %
            % T2 must be a table containing at least the same predictor columns as used
            % during training. For details, enter:
            %   trainedModel.HowToPredict

            % Auto-generated by MATLAB on 20-Dec-2018 20:33:32


            % Extract predictors and response
            % This code processes the data into the right shape for training the
            % model.
            inputTable = trainingData;
            predictorNames = {'activity'};
            predictors = inputTable(:, predictorNames);
            response = inputTable.predActivity;
            isCategoricalPredictor = [false];

            % Train a regression model
            % This code specifies all the model options and trains the model.
            regressionGP = fitrgp(...
                predictors, ...
                response, ...
                'BasisFunction', 'constant', ...
                'KernelFunction', 'squaredexponential', ...
                'Standardize', true);

            % Create the result struct with predict function
            predictorExtractionFcn = @(t) t(:, predictorNames);
            gpPredictFcn = @(x) predict(regressionGP, x);
            trainedModel.predictFcn = @(x) gpPredictFcn(predictorExtractionFcn(x));

            % Add additional fields to the result struct
            trainedModel.RequiredVariables = {'activity'};
            trainedModel.RegressionGP = regressionGP;
            trainedModel.About = 'This struct is a trained model exported from Regression Learner R2018a.';
            trainedModel.HowToPredict = sprintf('To make predictions on a new table, T, use: \n  yfit = c.predictFcn(T) \nreplacing ''c'' with the name of the variable that is this struct, e.g. ''trainedModel''. \n \nThe table, T, must contain the variables returned by: \n  c.RequiredVariables \nVariable formats (e.g. matrix/vector, datatype) must match the original training data. \nAdditional variables are ignored. \n \nFor more information, see <a href="matlab:helpview(fullfile(docroot, ''stats'', ''stats.map''), ''appregression_exportmodeltoworkspace'')">How to predict using an exported model</a>.');

            % Extract predictors and response
            % This code processes the data into the right shape for training the
            % model.
            inputTable = trainingData;
            predictorNames = {'activity'};
            predictors = inputTable(:, predictorNames);
            response = inputTable.predActivity;
            isCategoricalPredictor = [false];

            % Perform cross-validation
            partitionedModel = crossval(trainedModel.RegressionGP, 'KFold', 5);

            % Compute validation predictions
            validationPredictions = kfoldPredict(partitionedModel);

            % Compute validation RMSE
            validationRMSE = sqrt(kfoldLoss(partitionedModel, 'LossFun', 'mse'));
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        indexBestActivity_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


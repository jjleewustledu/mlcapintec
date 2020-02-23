classdef ApertureCalibration < handle & mlcapintec.AbstractCalibration
	%% APERTURECALIBRATION  

	%  $Revision$
 	%  was created 06-Nov-2018 14:57:13 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
        FILENAME = 'CCIRRadMeasurements 2017dec6.xlsx'
 		BEST_VOLUME = 0.5 % mL
    end
    
    methods (Static)
        function [this,h1,h2] = screenInvEfficiency()
            %% displays a table of voluem, specific activity and efficiency^{-1}, and plots thereof.
            %  @return call this.trainModelInvEff if this.trainedModelInvEff is empty.
            %  @return this is the ApertureCalibration.
            %  @return h1, h2 are figure handles to plots from "volume" to "specific activity" and "efficiency^{-1}".
            
            radMeas = mlpet.CCIRRadMeasurements.createByDate(datetime(2017,12,6));
            this = mlcapintec.ApertureCalibration(radMeas);            
            tbl = table(this);
            
            disp(tbl);
            h1 = figure;
            plot(tbl.volume, tbl.specificActivity, 'o', 'LineStyle', 'none');
            xlabel('volume / mL');
            ylabel('specific activity / (Bq/mL)');
            h2 = figure;
            plot(tbl.volume, tbl.invEfficiency, 'o', 'LineStyle', 'none');
            xlabel('volume / mL');
            ylabel('efficiency^{-1}');
            
            this.selfCalibrate;
        end
    end

	methods 
        
        %%
        
        function ie   = predictInvEff(this, varargin)
            %% PREDICTINVEFF predicts efficiency^{-1} from sample volumes.
            %  @param volume is table || is numeric.
            %  @return ie is numeric.
            
            ip = inputParser;
            addParameter(ip, 'volume', @(x) istable(x) || isnumeric(x));
            parse(ip, varargin{:});
            v = ip.Results.volume;
            
            if (isnumeric(v))
                v = ensureColVector(v);
                v = table(v);
            end
            assert(istable(v));
            assert(~isempty(this.trainedModelInvEff));
            ie = this.trainedModelInvEff.predictFcn(v);
        end
        function tbl  = table(this, varargin)
            %% TABLE
            %  @return table(..., 'VariableNames', {'volume' 'specificActivity' 'invEfficiency'}, varargin{:})
            %  for decay-corrected specificActivity and invEfficiency := specificActivity / specificActivity(BEST_VOLUME); 
            
            import mlcapintec.ApertureCalibration;
            import mlpet.Radionuclides.halflifeOf;
            v  = this.wellCounter.MassSample_G / ApertureCalibration.WATER_DENSITY; % mL
            t  = this.wellCounter.TIMECOUNTED_Hh_mm_ss; % datetime
            a  = this.wellCounter.Ge_68_Kdpm * (1e3/60); % Bq
            hl = seconds(halflifeOf('[18F]')); % duration
            a  = a .* 2.^((t - t(1))/hl); % Bq, decay-corrected
            sa = a ./ v; % Bq/mL
            ie = mean(sa(0.9*this.BEST_VOLUME <= v & v <= this.BEST_VOLUME*1.1)) ./ sa;
            assert(all(~isnan(ie)), 'mlcapintec:ValueError', 'ApertureCalibration.table');
            
            tbl = table(v, sa, ie, 'VariableNames', {'volume' 'specificActivity' 'invEfficiency'}, varargin{:});
        end
		  
 		function this = ApertureCalibration(varargin)
 			%% APERTURECALIBRATION

            this = this@mlcapintec.AbstractCalibration(varargin{:});
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)        
        function g = getTrainedModelInvEff__(this)
            g = this.trainedModelInvEff_;
        end
        function g = getTrainedModelInvEff_mat__(~)
            g = fullfile( ...
                mlpipeline.ResourcesRegistry.instance().matlabDrive, ...
                'mlcapintec', 'src', '+mlcapintec', 'trainedModelInvEffAperature.mat');
        end
        function [trainedModel, validationRMSE] = trainRegressionLearner__(~, trainingData)
            % [trainedModel, validationRMSE] = trainRegressionLearner__(trainingData)
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
            %   [trainedModel, validationRMSE] = trainRegressionLearner__(T)
            %
            % To make predictions with the returned 'trainedModel' on new data T2, use
            %   yfit = trainedModel.predictFcn(T2)
            %
            % T2 must be a table containing at least the same predictor columns as used
            % during training. For details, enter:
            %   trainedModel.HowToPredict
            
            % Auto-generated by MATLAB on 07-Nov-2018 02:57:08
            
            
            % Extract predictors and response
            % This code processes the data into the right shape for training the
            % model.
            inputTable = trainingData;
            predictorNames = {'volume'};
            predictors = inputTable(:, predictorNames);
            response = inputTable.invEfficiency;
            isCategoricalPredictor = false; %#ok<NASGU>
            
            % Train a regression model
            % This code specifies all the model options and trains the model.
            responseScale = iqr(response);
            if ~isfinite(responseScale) || responseScale == 0.0
                responseScale = 1.0;
            end
            boxConstraint = responseScale/1.349;
            epsilon = responseScale/13.49;
            regressionSVM = fitrsvm(...
                predictors, ...
                response, ...
                'KernelFunction', 'polynomial', ...
                'PolynomialOrder', 2, ...
                'KernelScale', 'auto', ...
                'BoxConstraint', boxConstraint, ...
                'Epsilon', epsilon, ...
                'Standardize', true);
            
            % Create the result struct with predict function
            predictorExtractionFcn = @(t) t(:, predictorNames);
            svmPredictFcn = @(x) predict(regressionSVM, x);
            trainedModel.predictFcn = @(x) svmPredictFcn(predictorExtractionFcn(x));
            
            % Add additional fields to the result struct
            trainedModel.RequiredVariables = {'volume'};
            trainedModel.RegressionSVM = regressionSVM;
            trainedModel.About = 'This struct is a trained model exported from Regression Learner R2018a.';
            trainedModel.HowToPredict = sprintf('To make predictions on a new table, T, use: \n  yfit = c.predictFcn(T) \nreplacing ''c'' with the name of the variable that is this struct, e.g. ''trainedModel''. \n \nThe table, T, must contain the variables returned by: \n  c.RequiredVariables \nVariable formats (e.g. matrix/vector, datatype) must match the original training data. \nAdditional variables are ignored. \n \nFor more information, see <a href="matlab:helpview(fullfile(docroot, ''stats'', ''stats.map''), ''appregression_exportmodeltoworkspace'')">How to predict using an exported model</a>.');
            
            % Extract predictors and response
            % This code processes the data into the right shape for training the
            % model.
            inputTable = trainingData;
            predictorNames = {'volume'};
            predictors = inputTable(:, predictorNames);
            response = inputTable.invEfficiency;
            isCategoricalPredictor = false;
            
            % Perform cross-validation
            KFolds = 5;
            cvp = cvpartition(size(response, 1), 'KFold', KFolds);
            % Initialize the predictions to the proper sizes
            validationPredictions = response;
            for fold = 1:KFolds
                trainingPredictors = predictors(cvp.training(fold), :);
                trainingResponse = response(cvp.training(fold), :);
                foldIsCategoricalPredictor = isCategoricalPredictor; %#ok<NASGU>
                
                % Train a regression model
                % This code specifies all the model options and trains the model.
                responseScale = iqr(trainingResponse);
                if ~isfinite(responseScale) || responseScale == 0.0
                    responseScale = 1.0;
                end
                boxConstraint = responseScale/1.349;
                epsilon = responseScale/13.49;
                regressionSVM = fitrsvm(...
                    trainingPredictors, ...
                    trainingResponse, ...
                    'KernelFunction', 'polynomial', ...
                    'PolynomialOrder', 2, ...
                    'KernelScale', 'auto', ...
                    'BoxConstraint', boxConstraint, ...
                    'Epsilon', epsilon, ...
                    'Standardize', true);
                
                % Create the result struct with predict function
                svmPredictFcn = @(x) predict(regressionSVM, x);
                validationPredictFcn = @(x) svmPredictFcn(x);
                
                % Add additional fields to the result struct
                
                % Compute validation predictions
                validationPredictors = predictors(cvp.test(fold), :);
                foldPredictions = validationPredictFcn(validationPredictors);
                
                % Store predictions in the original order
                validationPredictions(cvp.test(fold), :) = foldPredictions;
            end
            
            % Compute validation RMSE
            isNotMissing = ~isnan(validationPredictions) & ~isnan(response);
            validationRMSE = sqrt(nansum(( validationPredictions - response ).^2) / numel(response(isNotMissing) ));
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


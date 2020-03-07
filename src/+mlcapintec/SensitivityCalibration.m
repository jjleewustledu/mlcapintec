classdef SensitivityCalibration < handle & mlpet.AbstractCalibration
	%% SENSITIVITYCALIBRATION  

	%  $Revision$
 	%  was created 06-Nov-2018 14:57:03 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
 		BEST_ACTIVITY = 1e3 % kdpm
        BEST_DATETIME = datetime(2017,9,6)
    end
    
    properties (Dependent)
        indexBestActivity
        invEfficiency
    end
    
    methods (Static)
        function mat = buildCalibration()
            %% uses regressionLearner, decay-in-place data from 2017sep6
            %  @return mat is tranedModelInveff_sensitivity.mat
            
            rm = mlpet.CCIRRadMeasurements.createByDate(mlcapintec.SensitivityCalibration.BEST_DATETIME);
            this = mlcapintec.SensitivityCalibration(rm);
            
            datapath = fullfile(MatlabRegistry.instance.srcroot, 'mlcapintec', 'data', '');            
            mat = fullfile(datapath, 'trainedModelInvEff_sensitivity.mat');
            if isfile(mat)
                plot(this)
                return
            end
            
            tbl = table(this, 'model', 'regressionLearner');
            tbl.Properties.Description = 'from mlcapintec.SensitivityCalibration.buildCalibration()';
            save(fullfile(datapath, 'decay_in_place2.mat'), 'tbl')   
            ge68 = tbl.ge68;
            inveff = tbl.inveff;
            trainedModelInvEff_sensitivity = this.trainRegressionModel(table(ge68, inveff));
            save(fullfile(datapath, 'trainedModelInvEff_sensitivity.mat'), 'trainedModelInvEff_sensitivity');
        end
        function this = createBySession(varargin)
            %% CREATEBYSESSION
            %  @param required sessionData is an mlpipeline.ISessionData.
            %  See also:  mlpet.CCIRRadMeasurements.createBySession().
            
            rad = mlpet.CCIRRadMeasurements.createBySession(varargin{:});
            this = mlcapintec.SensitivityCalibration.createByRadMeasurements(rad);
        end
        function this = createByRadMeasurements(rad)
            %% CREATEBYRADMEASUREMENTS
 			%  @param required radMeasurements is mlpet.CCIRRadMeasurements.

            assert(isa(rad, 'mlpet.CCIRRadMeasurements'))
            this = mlcapintec.SensitivityCalibration(rad);
        end 
        function inveff = invEfficiencyf(varargin)
            %% INVEFFICIENCYF is derived from studies of aq. [18F]DG on 2017sep6.
            %  @param required ge68 in kdpm.
            %  @return inveff:  predicted := inveff .* measured.
            
            ip = inputParser;
            addRequired(ip, 'ge68', @isnumeric) % kdpm
            parse(ip, varargin{:})
            
            srcroot = MatlabRegistry.instance.srcroot;
            obj = load(fullfile(srcroot, 'mlcapintec', 'data', 'trainedModelInvEff_sensitivity.mat')); 
            ge68 = ip.Results.ge68;
            T = table(ge68);
            inveff = obj.trainedModelInvEff_sensitivity.predictFcn(T);
        end
    end
    
	methods
        
        %% GET
        
        function g = get.indexBestActivity(this)
            if (isempty(this.indexBestActivity_))                
                da = this.radMeasurements.wellCounter.Ge_68_Kdpm - this.BEST_ACTIVITY; % kdpm
                [~,this.indexBestActivity_] = min(abs(da));
            end
            g = this.indexBestActivity_;
        end 
        function g = get.invEfficiency(~) %#ok<STOUT>
            error('mlcapintec:RuntimeError', 'SensitivityCalibration.get.invEfficiency:  use infEfficiencyf(mass)')
        end
        
        %%
        
        function [h1,h2] = plot(this, varargin)
            %% PLOT label activity vs. activity; activity vs. efficiency^{-1}.
            %  @return h1, h2 are figure handles.
                      
            tbl = table(this, varargin{:});
            label_ge68 = tbl.label_ge68;
            ge68 = tbl.ge68;
            inveff = tbl.inveff;            
            
            figure; 
            h1 = plot(label_ge68, ge68, '+');
            xlabel('label activity [^{18}F]DG / (kdpm/g)'); ylabel('activity [^{18}F]DG / (kdpm/g)');
            figure; 
            h2 = plot(ge68, inveff, '+');
            xlabel('activity [^{18}F]DG / (kdpm/g)'); ylabel('efficiency^{-1}');
        end
        function tbl  = table(this, varargin)
            %% TABLE
            %  @param varargin is passed to this.invEfficiencyf().
            %  @return table(mass, ge68, label_ge68, dtime, inveff).
            
            well = this.radMeasurements.wellCounter;
            
            dtime = seconds(well.TIMECOUNTED_Hh_mm_ss - well.TIMECOUNTED_Hh_mm_ss(this.indexBestActivity));
            mass  = well.MassSample_G;
            ge68  = well.Ge_68_Kdpm;
            ge68  = mlcapintec.ApertureCalibration.invEfficiencyf(mass, varargin{:}) .* ge68;
            label_ge68 = ge68(this.indexBestActivity) * (mass/mass(this.indexBestActivity)) .* 2.^(-dtime/6586.272);
            inveff = label_ge68 ./ ge68;  
            
            tbl = table(mass, ge68, label_ge68, dtime, inveff);
            tbl.Properties.VariableUnits = {'g' 'kdpm' 'kdpm' 's', ''};
        end
        function [trainedModel, validationRMSE] = trainRegressionModel(~, trainingData)
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
            
            % Auto-generated by MATLAB on 24-Feb-2020 02:24:14
            
            
            % Extract predictors and response
            % This code processes the data into the right shape for training the
            % model.
            inputTable = trainingData;
            predictorNames = {'ge68'};
            predictors = inputTable(:, predictorNames);
            response = inputTable.inveff;
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
            trainedModel.RequiredVariables = {'ge68'};
            trainedModel.RegressionGP = regressionGP;
            trainedModel.About = 'This struct is a trained model exported from Regression Learner R2019b.';
            trainedModel.HowToPredict = sprintf('To make predictions on a new table, T, use: \n  yfit = c.predictFcn(T) \nreplacing ''c'' with the name of the variable that is this struct, e.g. ''trainedModel''. \n \nThe table, T, must contain the variables returned by: \n  c.RequiredVariables \nVariable formats (e.g. matrix/vector, datatype) must match the original training data. \nAdditional variables are ignored. \n \nFor more information, see <a href="matlab:helpview(fullfile(docroot, ''stats'', ''stats.map''), ''appregression_exportmodeltoworkspace'')">How to predict using an exported model</a>.');
            
            % Extract predictors and response
            % This code processes the data into the right shape for training the
            % model.
            inputTable = trainingData;
            predictorNames = {'ge68'};
            predictors = inputTable(:, predictorNames);
            response = inputTable.inveff;
            isCategoricalPredictor = [false];
            
            % Perform cross-validation
            partitionedModel = crossval(trainedModel.RegressionGP, 'KFold', 5);
            
            % Compute validation predictions
            validationPredictions = kfoldPredict(partitionedModel);
            
            % Compute validation RMSE
            validationRMSE = sqrt(kfoldLoss(partitionedModel, 'LossFun', 'mse'));
        end
        
 		function this = SensitivityCalibration(varargin)
 			%% SENSITIVITYCALIBRATION
 			%  @param .

 			this = this@mlpet.AbstractCalibration(varargin{:});
 		end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        indexBestActivity_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


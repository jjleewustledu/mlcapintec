classdef ApertureCalibration < handle & mlpet.AbstractCalibration
	%% APERTURECALIBRATION  

	%  $Revision$
 	%  was created 06-Nov-2018 14:57:13 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
        BEST_DATETIME = datetime(2017,12,6)
 		BEST_VOLUME = 0.5 % mL
    end
    
    properties (Dependent)
        calibrationAvailable
        invEfficiency
    end
    
    methods (Static)
        function mat = buildCalibration()
            %% uses regression learner, decay-in-place data from 2017dec6; 
            %  labels corrected with reference source calibrations';
            %  @return mat is tranedModelInveff_aperature.mat
            
            rm = mlpet.CCIRRadMeasurements.createFromDate(mlcapintec.ApertureCalibration.BEST_DATETIME);
            this = mlcapintec.ApertureCalibration(rm);
            
            datapath = fullfile(MatlabRegistry.instance.srcroot, 'mlcapintec', 'data', '');
            mat = fullfile(datapath, 'trainedModelInvEff_aperture.mat');
            if isfile(mat)            
                plot(this, 'NaN_14')
                return
            end            
            
            tbl = table(this, 'NaN_14');
            tbl.Properties.Description = 'from mlcapintec.ApertureCalibration.buildCalibration()';            
            save(fullfile(datapath, 'decay_in_place.mat'), 'tbl')
            
            vol = tbl.vol;
            inveff = tbl.inveff;
            trainedModelInvEff_aperture = this.trainRegressionModel(table(vol, inveff));
            save(fullfile(datapath, 'trainedModelInvEff_aperture.mat'), 'trainedModelInvEff_aperture');
            
        end   
        function this = createFromSession(varargin)
            %% CREATEBYSESSION
            %  @param required sessionData is an mlpipeline.ISessionData.
            %  See also:  mlpet.CCIRRadMeasurements.createFromSession().
            
            rad = mlpet.CCIRRadMeasurements.createFromSession(varargin{:});
            this = mlcapintec.ApertureCalibration.createFromRadMeasurements(rad);
        end
        function this = createFromRadMeasurements(rad)
            %% CREATEBYRADMEASUREMENTS
 			%  @param required radMeasurements is mlpet.CCIRRadMeasurements.

            assert(isa(rad, 'mlpet.CCIRRadMeasurements'))
            this = mlcapintec.ApertureCalibration(rad);
        end    
        function inveff = invEfficiencyf(varargin)
            %% INVEFFICIENCYF is derived from studies of aq. [18F]DG on 2017dec6.
            %  @param required mass in g.
            %  @param solvent in {'water' 'plasma' 'blood'}
            %  @param model in {'polynomial', 'regressionLearner', 'none'}.
            %  @return inveff:  predicted := inveff .* measured.
            
            import mlcapintec.ApertureCalibration
            
            ip = inputParser;
            addRequired(ip, 'mass', @isnumeric)
            addParameter(ip, 'solvent', 'water', @ischar)
            addParameter(ip, 'model', 'regressionLearner', @ischar);
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            switch (ipr.solvent)
                case 'water'
                    vol = ascol(ipr.mass)/ApertureCalibration.WATER_DENSITY;
                case 'blood'
                    vol = ascol(ipr.mass)/ApertureCalibration.BLOOD_DENSITY;
                case 'plasma'
                    vol = ascol(ipr.mass)/ApertureCalibration.PLASMA_DENSITY;
                otherwise
                    error('mlcapintec:NotImplementedError', ...
                        'ApertureCalibration.invEfficiency.ipr.solvent->%s', ipr.solvent)
            end            
            switch (ipr.model)
                case 'polynomial'
                    inveff = 1592.7 ./ ...
                        (53.495*vol.^3 - 298.43*vol.^2 + 191.17*vol + 1592.7);
                case 'regressionLearner'
                    srcroot = MatlabRegistry.instance.srcroot;
                    obj = load(fullfile(srcroot, 'mlcapintec', 'data', 'trainedModelInvEff_aperture.mat')); 
                    T = table(vol);
                    inveff = obj.trainedModelInvEff_aperture.predictFcn(T);
                case 'none'
                    inveff = ones(size(vol));
                otherwise 
                    error('mlcapintec:NotImplementedError', ...
                        'ApertureCalibration.invEfficiency.ipr.model->%s', ipr.model)
            end
        end
    end

	methods 
        
        %% GET
        
        function g = get.calibrationAvailable(~)
            g = true;
        end
        function g = get.invEfficiency(~) %#ok<STOUT>
            error('mlcapintec:RuntimeError', 'ApertureCalibration.get.invEfficiency:  use infEfficiencyf(mass)')
        end
        
        %%
        
        function [h1,h2,h3] = plot(this, varargin)
            %% PLOT mass versus {activity, specific activity, efficiency^{-1}}
            %  @param optional arow for table(this, arow) is char.
            %  @return h1, h2, h3 are figure handles.
                      
            tbl = table(this, varargin{:});
            mass = tbl.mass;
            vol = tbl.vol;
            label_ge68 = tbl.label_ge68;
            ge68 = tbl.ge68;
            label_specific_activity = tbl.label_specific_activity;
            specific_activity = tbl.specific_activity;
            inveff = tbl.inveff;
            
            figure; 
            h1 = plot(mass, label_ge68, ':o', mass, ge68, ':o');
            xlabel('mass / g'); ylabel('activity / kdpm'); legend('label [^{18}F]DG', '[^{18}F]DG');
            figure; 
            h2 = plot(mass, label_specific_activity, ':o', mass, specific_activity, ':o');
            xlabel('mass / g'); ylabel('specific activity / (kdpm/g)'); legend('label [^{18}F]DG', '[^{18}F]DG');
            figure; 
            h3 = plot(vol, inveff, ':o');
            xlabel('volume / mL'); ylabel('efficiency^{-1}');
        end
        function tbl = table(this, varargin)
            %% TABLE
            %  @param arow is char.
            %  @return table(mass, ge68, label_ge68, specific_activity, label_specific_activity, dtime, inveff).
            
            ip = inputParser;
            addOptional(ip, 'arow', 'NaN_14', @ischar)
            addParameter(ip, 'rowSelect', 2:24, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            well = this.radMeasurements.wellCounter;
            
            % dtime, ge68, mass, specific_activity from 'aperture data from 2017dec6.numbers' 
            dtime = seconds(well.TIMECOUNTED_Hh_mm_ss(ipr.rowSelect) - well.TIMECOUNTED_Hh_mm_ss(ipr.arow));
            mass  = well.MassSample_G(ipr.rowSelect);
            vol   = mass/mlcapintec.ApertureCalibration.WATER_DENSITY;
            ge68  = well.Ge_68_Kdpm(ipr.rowSelect);
            
            ieGe68 = mlcapintec.RefSourceCalibration.Ge68_PREDICTED_OVER_Ge68_MEASURED;
            label_ge68 = ieGe68 * well.Ge_68_Kdpm(ipr.arow) .* 2.^(-dtime/6586.272) .* mass / well.MassSample_G(ipr.arow);
            label_specific_activity = label_ge68 ./ mass;
            specific_activity = ge68 ./ mass;
            inveff = label_ge68 ./ ge68; 
            
            tbl = table(mass, vol, ge68, label_ge68, specific_activity, label_specific_activity, dtime, inveff);
            tbl.Properties.VariableUnits = {'g' 'mL' 'kdpm' 'kdpm' 'kdpm/g' 'kdpm/g' 's' ''};
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
            
            % Auto-generated by MATLAB on 24-Feb-2020 02:45:34
            
            
            % Extract predictors and response
            % This code processes the data into the right shape for training the
            % model.
            inputTable = trainingData;
            predictorNames = {'vol'};
            predictors = inputTable(:, predictorNames);
            response = inputTable.inveff;
            isCategoricalPredictor = [false];
            
            % Train a regression model
            % This code specifies all the model options and trains the model.
            regressionGP = fitrgp(...
                predictors, ...
                response, ...
                'BasisFunction', 'constant', ...
                'KernelFunction', 'rationalquadratic', ...
                'Standardize', true);
            
            % Create the result struct with predict function
            predictorExtractionFcn = @(t) t(:, predictorNames);
            gpPredictFcn = @(x) predict(regressionGP, x);
            trainedModel.predictFcn = @(x) gpPredictFcn(predictorExtractionFcn(x));
            
            % Add additional fields to the result struct
            trainedModel.RequiredVariables = {'vol'};
            trainedModel.RegressionGP = regressionGP;
            trainedModel.About = 'This struct is a trained model exported from Regression Learner R2019b.';
            trainedModel.HowToPredict = sprintf('To make predictions on a new table, T, use: \n  yfit = c.predictFcn(T) \nreplacing ''c'' with the name of the variable that is this struct, e.g. ''trainedModel''. \n \nThe table, T, must contain the variables returned by: \n  c.RequiredVariables \nVariable formats (e.g. matrix/vector, datatype) must match the original training data. \nAdditional variables are ignored. \n \nFor more information, see <a href="matlab:helpview(fullfile(docroot, ''stats'', ''stats.map''), ''appregression_exportmodeltoworkspace'')">How to predict using an exported model</a>.');
            
            % Extract predictors and response
            % This code processes the data into the right shape for training the
            % model.
            inputTable = trainingData;
            predictorNames = {'vol'};
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
		  
 		function this = ApertureCalibration(varargin)
 			%% APERTURECALIBRATION

            this = this@mlpet.AbstractCalibration(varargin{:});
 		end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


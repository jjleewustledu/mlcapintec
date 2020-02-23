classdef CapracCalibration < handle & mlcapintec.AbstractCalibration
	%% CAPRACCALIBRATION  

	%  $Revision$
 	%  was created 06-Nov-2018 14:46:31 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.

    properties (Constant)
        ACTIVITY_MEASURED_MINUS_ACTIVITY_PREDICTED = -10.9813 % Bq/mL
    end
    
    methods (Static)
        function mat = buildApertureCorrection()
            %% given to regression learner
            %  @return mat is tranedModelInveff.mat
            
            % dtime, ge68, mass, specific_activity from 'aperture data from 2017dec6.numbers'                    
            label_ge68 = (741.1 + 10.9813*60/1e3) .* 2.^(-dtime/6586.272) .* mass ./ 0.4998;
            label_specific_activity = label_ge68 ./ mass;
            inveff = label_ge68 ./ ge68;                    

            tbl = table(dtime, ge68, mass, specific_activity, label_ge68, label_specific_activity, inveff);
            tbl.Properties.Description = 'Decay-in-place data from 2017dec6; labels corrected with reference source calibrations';
            tbl.Properties.VariableUnits = {'s' 'kdpm' 'g' 'kdpm/g' 'kdpm' 'kdpm/g' ''};
            save('decay_in_place.mat', 'tbl')
            
            trainedModelInveff = [];
            regressionLearner
            mat = fullfile(MatlabRegistry.instance.srcroot, 'mlcapintec', 'data', 'trainedModelInveff.mat');
            save(mat, 'trainedModelInveff')

            figure; plot(mass, label_ge68, ':o', mass, ge68, ':o')
            figure; plot(mass, label_specific_activity, ':o', mass, specific_activity, ':o')
            figure; plot(mass, inveff)            
        end
        function inveff = invEfficiencyf(mass, sa, varargin)
            %% INVEFFICIENCYF is derived from studies of aq. [18F]DG on 2017dec6.
            %  @param required mass in g.
            %  @param optional specific activity in kdpm/g, energy windows for [68Ge].
            %  @param model in {'polynomial', 'machine'}.
            %  @return inveff:  predicted := inveff .* measured.
            
            import mlcapintec.CapracCalibration
            
            ip = inputParser;
            addRequired(ip, 'mass', @isnumeric)
            addOptional(ip, 'sa', @isnumeric)
            addParameter(ip, 'solvent', 'water', @ischar)
            addParameter(ip, 'model', 'machine', @ischar);
            parse(ip, sa, mass, varargin{:})
            ipr = ip.Results;
            
            switch (ipr.solvent)
                case 'water'
                    mass = ascol(ipr.mass);
                case 'blood'
                    mass = ascol(ipr.mass)*CapracCalibration.WATER_DENSITY/CapracCalibration.BLOOD_DENSITY;
                otherwise
                    error('mlcapintec:NotImplementedError', ...
                        'CapracCalibration.invEfficiency.ipr.solvent->%s', ipr.solvent)
            end            
            switch (ipr.model)
                case 'polynomial'
                    inveff = (ipr.sa)*1592.7 ./ ...
                        (53.495*mass.^3 - 298.43*mass.^2 + 191.17*mass + 1592.7);
                case 'machine'
                    srcroot = MatlabRegistry.instance.srcroot;
                    obj = load(fullfile(srcroot, 'mlcapintec', 'data', 'trainedModelInveff.mat'));                    
                    ge68 = ascol(ipr.sa) .* ascol(ipr.mass);
                    T = table(ge68, mass);
                    inveff = obj.trainedModelInveff.predictFcn(T);
                otherwise 
                    error('mlcapintec:NotImplementedError', ...
                        'CapracCalibration.invEfficiency.ipr.model->%s', ipr.model)
            end
        end
        function plotRefSourceStability(isotope)
            %% ref measurement datetimes are enumerated in file 'cross-calibrations_20190817.xlsx'
            
            import mlcapintec.CapracCalibration
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
                    dts(1) = datetime(2018,8,13,  'TimeZone', tz);
                    dts(2) = datetime(2018,10,5,  'TimeZone', tz);
                    dts(3) = datetime(2018,11,13, 'TimeZone', tz);
                    dts(4) = datetime(2018,12,13, 'TimeZone', tz);
                    dts(5) = datetime(2018,12,18, 'TimeZone', tz);
                    dts(6) = datetime(2019,1,8,   'TimeZone', tz);
                    dts(7) = datetime(2019,1,10,  'TimeZone', tz);
                    dts(8) = datetime(2019,5,23,  'TimeZone', tz);                    
                case '22Na'
                    ref = ReferenceSource( ...
                        'isotope', '22Na', ...
                        'activity', 101.4, ...
                        'activityUnits', 'nCi', ...
                        'sourceId', '1382-54-1', ...
                        'refDate', datetime(2009,8,1, 'TimeZone', tz));                
                    dts(1) = datetime(2018,9,12,  'TimeZone', tz);
                    dts(2) = datetime(2018,10,5,  'TimeZone', tz);
                case '68Ge'
                    ref = ReferenceSource( ...
                        'isotope', '68Ge', ...
                        'activity', 101.3, ...
                        'activityUnits', 'nCi', ...
                        'sourceId', '1932-53', ...
                        'refDate', datetime(2017,11,1, 'TimeZone', tz), ...
                        'productCode', 'MGF-068-R3');
                    dts(1) = datetime(2018,9,12,  'TimeZone', tz);
                    dts(2) = datetime(2018,10,5,  'TimeZone', tz);
                otherwise
                    error('mlcapintec:NotImplementedError', ...
                        'CapracCalibration.plotRefSourceStability.isotope->%s', isotope)
            end
            
            CapracCalibration.plot_datetime2RefSourceDeviation(ref, dts)
        end
        function sa = specificActivityf(mass, sa, varargin)
            %% INVEFFICIENCYF is derived from studies of aq. [18F]DG on 2017dec6.
            %  @param required mass in g.
            %  @param optional specific activity in kdpm/g, energy windows for [68Ge].
            %  @param model in {'polynomial', 'machine'}.
            %  @return sa:  predicted := inveff .* measured.
            
            ie = mlcapintec.CapracCalibration.invEfficiencyf(mass, sa, varargin{:});
            sa = ie .* sa;
        end
    end
    
	methods 		  
 		function this = CapracCalibration(varargin)
 			%% CAPRACCALIBRATION
            
            this = this@mlpet.AbstractCalibration(varargin{:});
 		end
    end 
    
    %% PROTECTED
    
    methods (Static, Access = protected) 
        function plot_datetime2RefSourceDeviation(ref, dts)
            tra = sprintf('[%s]', ref.isotope);
            datetimeMeas = [];
            activityMeas = [];
            activityPred = [];
            for d = 1:length(dts)
                ccir = mlpet.CCIRRadMeasurements.createByDate(dts(d));
                wc = ccir.wellCounter;
                time = wc.TIMECOUNTED_Hh_mm_ss(strcmp(wc.TRACER, tra));
                time = time(~isnat(time));
                if strcmp(tra, '137Cs')
                    meas = wc.CF_Kdpm(strcmp(wc.TRACER, tra));
                else
                    meas = wc.Ge_68_Kdpm(strcmp(wc.TRACER, tra));
                end
                meas = meas(~isnan(meas));
                pred = ref.predictedActivity(dts(d), 'kdpm')*ones(size(meas));
                datetimeMeas = [datetimeMeas; time];
                activityMeas = [activityMeas; meas]; %#ok<*AGROW>
                activityPred = [activityPred; pred];
            end
            
            figure
            plot(datetimeMeas, activityMeas - activityPred, ':o')
            title(sprintf('[%s] ref source measurement stability on Caprac over time', ref.isotope))
            xlabel('datetime')
            ylabel('(measured activity - predicted activity) / kdpm')
            fprintf('(activityMeas - activityPred) / (Bq/mL)\n')
            disp((activityMeas - activityPred)*1e3/60)
            fprintf('mean(activityMeas - activityPred) -> %g Bq/mL\n', mean(activityMeas - activityPred)*1e3/60)
        end
    end
    
    methods (Access = protected)
        function g = getTrainedModelInvEff_mat__(~)
            srcroot = MatlabRegistry.instance.srcroot;
            g = fullfile(srcroot, 'mlcapintec', 'data', 'trainedModelInveff.mat');
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


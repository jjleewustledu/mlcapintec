classdef Test_CapracCalibration < matlab.unittest.TestCase
	%% TEST_CAPRACCALIBRATION 

	%  Usage:  >> results = run(mlcapintec_unittest.Test_CapracCalibration)
 	%          >> result  = run(mlcapintec_unittest.Test_CapracCalibration, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 21-Dec-2018 19:10:16 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/test/+mlcapintec_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        radMeas
        refSources
 		registry
        session
 		testObj
 	end

	methods (Test)
        function test_ctor(this)
            disp(this.radMeas)
            disp(this.refSources)
            disp(this.session)
        end
        function test_ApertureCalibration_invEfficiencyf(this)
            import mlcapintec.ApertureCalibration
            
            % from CCIRRadMeasurements 2017dec6.numbers, Twilite Calibration, WELL COUNTER;
            % assessing aperture corrected spec. activities in kdpm/g
            this.verifyEqual( ...
                1078*ApertureCalibration.invEfficiencyf(0.2236, 'model', 'polynomial')/0.2236, 4736.58, 'RelTol', 1e-4)
            this.verifyEqual( ...
                1632*ApertureCalibration.invEfficiencyf(1.0908, 'model', 'polynomial')/1.0908, 1572.83750195537, 'RelTol', 1e-4)
            this.verifyEqual( ...
                2975*ApertureCalibration.invEfficiencyf(2.2824, 'model', 'polynomial')/2.2824, 1871.84967061124, 'RelTol', 1e-4)
              
            this.verifyEqual( ...
                1078*ApertureCalibration.invEfficiencyf(0.2236, 'model', 'regressionLearner')/0.2236, 4449.14611689021, 'RelTol', 1e-4)
            this.verifyEqual( ...
                1632*ApertureCalibration.invEfficiencyf(1.0908, 'model', 'regressionLearner')/1.0908, 1607.58276543806, 'RelTol', 1e-4)
            this.verifyEqual( ...
                2975*ApertureCalibration.invEfficiencyf(2.2824, 'model', 'regressionLearner')/2.2824, 1960.511260158, 'RelTol', 1e-4)
            
            this.verifyEqual( ...
                1078*ApertureCalibration.invEfficiencyf(0.2236, 'model', 'regressionLearner', 'solvent', 'blood')/0.2236, 4429.51543078802, 'RelTol', 1e-4)
            this.verifyEqual( ...
                1632*ApertureCalibration.invEfficiencyf(1.0908, 'model', 'regressionLearner', 'solvent', 'blood')/1.0908, 1591.34335501091, 'RelTol', 1e-4)
            this.verifyEqual( ...
                2975*ApertureCalibration.invEfficiencyf(2.2824, 'model', 'regressionLearner', 'solvent', 'blood')/2.2824, 1897.33927349619, 'RelTol', 1e-4)
        end
        function test_ApertureCalibration_plot(~)
            rm = mlpet.CCIRRadMeasurements.createFromDate(mlcapintec.ApertureCalibration.BEST_DATETIME);
            obj = mlcapintec.ApertureCalibration('radMeas', rm);
            plot(obj)
        end        
        function test_ApertureCalibration_table(~)
            rm = mlpet.CCIRRadMeasurements.createFromDate(mlcapintec.ApertureCalibration.BEST_DATETIME);
            obj = mlcapintec.ApertureCalibration('radMeas', rm);
            disp(table(obj))
        end
        function test_RefSourceCalibration_stability(~)
            mlcapintec.RefSourceCalibration.plotRefSourceStability('137Cs')
            mlcapintec.RefSourceCalibration.plotRefSourceStability('22Na')
            mlcapintec.RefSourceCalibration.plotRefSourceStability('68Ge')
            
            % mlcapintec.RefSourceCalibration.plotRefSourceStability('137Cs')
            % 
            % datetime -> 10-Aug-2018 18:01:00	 fileprefix -> CCIRRadMeasurements 2018aug10	 meas - pred -> -146.506 kdpm	 meas/pred -> 0.828649
            % datetime -> 10-Aug-2018 18:06:00	 fileprefix -> CCIRRadMeasurements 2018aug10	 meas - pred -> -146.406 kdpm	 meas/pred -> 0.828766
            % datetime -> 13-Aug-2018 15:36:00	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -149.845 kdpm	 meas/pred -> 0.824711
            % datetime -> 13-Aug-2018 15:40:00	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -145.645 kdpm	 meas/pred -> 0.829624
            % datetime -> 13-Aug-2018 15:44:00	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -148.345 kdpm	 meas/pred -> 0.826465
            % datetime -> 13-Aug-2018 16:57:00	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -146.945 kdpm	 meas/pred -> 0.828103
            % datetime -> 13-Aug-2018 17:00:00	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -146.745 kdpm	 meas/pred -> 0.828337
            % datetime -> 13-Aug-2018 17:02:30	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -145.345 kdpm	 meas/pred -> 0.829975
            % datetime -> 13-Aug-2018 17:34:15	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -150.045 kdpm	 meas/pred -> 0.824477
            % datetime -> 13-Aug-2018 17:36:00	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -148.145 kdpm	 meas/pred -> 0.826699
            % datetime -> 13-Aug-2018 17:38:40	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -146.745 kdpm	 meas/pred -> 0.828337
            % datetime -> 13-Aug-2018 17:41:30	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -148.645 kdpm	 meas/pred -> 0.826115
            % datetime -> 13-Aug-2018 17:43:41	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -149.245 kdpm	 meas/pred -> 0.825413
            % datetime -> 13-Aug-2018 17:47:00	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -147.945 kdpm	 meas/pred -> 0.826933
            % datetime -> 13-Aug-2018 17:49:05	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -148.045 kdpm	 meas/pred -> 0.826816
            % datetime -> 13-Aug-2018 17:51:00	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -148.345 kdpm	 meas/pred -> 0.826465
            % datetime -> 13-Aug-2018 17:53:30	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -149.545 kdpm	 meas/pred -> 0.825062
            % datetime -> 13-Aug-2018 17:55:12	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -147.645 kdpm	 meas/pred -> 0.827284
            % datetime -> 13-Aug-2018 17:57:00	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -147.545 kdpm	 meas/pred -> 0.827401
            % datetime -> 13-Aug-2018 17:58:30	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -147.545 kdpm	 meas/pred -> 0.827401
            % datetime -> 13-Aug-2018 18:00:05	 fileprefix -> CCIRRadMeasurements 2018aug13	 meas - pred -> -146.945 kdpm	 meas/pred -> 0.828103
            % datetime -> 13-Dec-2018 09:08:00	 fileprefix -> CCIRRadMeasurements 2018dec13	 meas - pred -> -146.307 kdpm	 meas/pred -> 0.82753
            % datetime -> 13-Dec-2018 09:13:00	 fileprefix -> CCIRRadMeasurements 2018dec13	 meas - pred -> -146.407 kdpm	 meas/pred -> 0.827412
            % datetime -> 13-Dec-2018 09:15:00	 fileprefix -> CCIRRadMeasurements 2018dec13	 meas - pred -> -146.007 kdpm	 meas/pred -> 0.827884
            % datetime -> 13-Dec-2018 09:18:00	 fileprefix -> CCIRRadMeasurements 2018dec13	 meas - pred -> -146.107 kdpm	 meas/pred -> 0.827766
            % datetime -> 13-Dec-2018 09:25:00	 fileprefix -> CCIRRadMeasurements 2018dec13	 meas - pred -> -146.007 kdpm	 meas/pred -> 0.827884
            % datetime -> 13-Dec-2018 09:27:00	 fileprefix -> CCIRRadMeasurements 2018dec13	 meas - pred -> -150.207 kdpm	 meas/pred -> 0.822933
            % datetime -> 13-Dec-2018 09:29:00	 fileprefix -> CCIRRadMeasurements 2018dec13	 meas - pred -> -145.607 kdpm	 meas/pred -> 0.828356
            % datetime -> 13-Dec-2018 09:30:00	 fileprefix -> CCIRRadMeasurements 2018dec13	 meas - pred -> -148.707 kdpm	 meas/pred -> 0.824701
            % datetime -> 13-Dec-2018 11:05:00	 fileprefix -> CCIRRadMeasurements 2018dec13	 meas - pred -> -146.907 kdpm	 meas/pred -> 0.826823
            % datetime -> 13-Dec-2018 11:15:00	 fileprefix -> CCIRRadMeasurements 2018dec13	 meas - pred -> -146.507 kdpm	 meas/pred -> 0.827295
            % datetime -> 18-Dec-2018 15:50:52	 fileprefix -> CCIRRadMeasurements 2018dec18	 meas - pred -> -147.417 kdpm	 meas/pred -> 0.826163
            % datetime -> 18-Dec-2018 16:08:41	 fileprefix -> CCIRRadMeasurements 2018dec18	 meas - pred -> -147.817 kdpm	 meas/pred -> 0.825691
            % datetime -> 13-Nov-2018 17:41:35	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -145.21 kdpm	 meas/pred -> 0.829147
            % datetime -> 13-Nov-2018 17:43:56	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -146.91 kdpm	 meas/pred -> 0.827147
            % datetime -> 13-Nov-2018 17:45:10	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -142.71 kdpm	 meas/pred -> 0.832088
            % datetime -> 13-Nov-2018 17:46:16	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -145.11 kdpm	 meas/pred -> 0.829265
            % datetime -> 13-Nov-2018 17:47:38	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -146.11 kdpm	 meas/pred -> 0.828088
            % datetime -> 13-Nov-2018 17:48:19	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -142.61 kdpm	 meas/pred -> 0.832206
            % datetime -> 13-Nov-2018 17:49:09	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -141.01 kdpm	 meas/pred -> 0.834089
            % datetime -> 13-Nov-2018 17:51:20	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -142.11 kdpm	 meas/pred -> 0.832794
            % datetime -> 13-Nov-2018 17:51:12	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -145.71 kdpm	 meas/pred -> 0.828559
            % datetime -> 13-Nov-2018 17:52:00	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -144.51 kdpm	 meas/pred -> 0.82997
            % datetime -> 13-Nov-2018 17:52:45	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -149.51 kdpm	 meas/pred -> 0.824088
            % datetime -> 13-Nov-2018 17:53:36	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -146.41 kdpm	 meas/pred -> 0.827735
            % datetime -> 13-Nov-2018 17:54:21	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -143.91 kdpm	 meas/pred -> 0.830676
            % datetime -> 13-Nov-2018 17:55:00	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -146.81 kdpm	 meas/pred -> 0.827264
            % datetime -> 13-Nov-2018 17:55:51	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -144.31 kdpm	 meas/pred -> 0.830206
            % datetime -> 13-Nov-2018 17:56:35	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -141.81 kdpm	 meas/pred -> 0.833147
            % datetime -> 13-Nov-2018 17:57:18	 fileprefix -> CCIRRadMeasurements 2018nov13	 meas - pred -> -148.21 kdpm	 meas/pred -> 0.825617
            % datetime -> 05-Oct-2018 10:53:25	 fileprefix -> CCIRRadMeasurements 2018oct5	 meas - pred -> -144.873 kdpm	 meas/pred -> 0.829956
            % datetime -> 05-Oct-2018 18:04:41	 fileprefix -> CCIRRadMeasurements 2018oct5	 meas - pred -> -144.573 kdpm	 meas/pred -> 0.830308
            % mean([activityMeas   activityPred]) -> 778.352 kdpm
            % mean( activityMeas - activityPred ) -> -146.511 kdpm
            %  std( activityMeas - activityPred ) -> 2.11182 kdpm
            % mean( activityMeas / activityPred ) -> 0.82796     
            %  std( activityMeas / activityPred ) -> 0.00234099     
            %                                   N -> 52
            %                            duration -> 129.964
            % 
            % mlcapintec.RefSourceCalibration.plotRefSourceStability('22Na')                           
            % 
            % datetime -> 08-Apr-2016 09:48:00	 fileprefix -> CCIRRadMeasurements 2016apr8	 meas - pred -> -0.642561 kdpm	 meas/pred -> 0.983069
            % datetime -> 08-Apr-2016 09:52:00	 fileprefix -> CCIRRadMeasurements 2016apr8	 meas - pred -> 0.137439 kdpm	 meas/pred -> 1.00362
            % datetime -> 08-Apr-2016 09:54:00	 fileprefix -> CCIRRadMeasurements 2016apr8	 meas - pred -> -0.122561 kdpm	 meas/pred -> 0.996771
            % datetime -> 05-Oct-2018 10:47:31	 fileprefix -> CCIRRadMeasurements 2018oct5	 meas - pred -> -0.38048 kdpm	 meas/pred -> 0.980539
            % datetime -> 05-Oct-2018 18:01:53	 fileprefix -> CCIRRadMeasurements 2018oct5	 meas - pred -> -0.78048 kdpm	 meas/pred -> 0.960079
            % datetime -> 12-Sep-2018 14:34:56	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> -0.338152 kdpm	 meas/pred -> 0.982997
            % datetime -> 12-Sep-2018 14:37:00	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> -1.36815 kdpm	 meas/pred -> 0.931208
            % datetime -> 12-Sep-2018 14:38:53	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> -0.558152 kdpm	 meas/pred -> 0.971935
            % datetime -> 12-Sep-2018 14:40:46	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> -0.818152 kdpm	 meas/pred -> 0.958862
            % datetime -> 12-Sep-2018 14:42:30	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> -0.368152 kdpm	 meas/pred -> 0.981489
            % datetime -> 12-Sep-2018 14:44:10	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> -0.308152 kdpm	 meas/pred -> 0.984506
            % datetime -> 12-Sep-2018 14:45:53	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> -0.718152 kdpm	 meas/pred -> 0.96389
            % datetime -> 12-Sep-2018 14:47:24	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> -0.748152 kdpm	 meas/pred -> 0.962382
            % datetime -> 12-Sep-2018 14:49:00	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> -0.898152 kdpm	 meas/pred -> 0.95484
            % datetime -> 12-Sep-2018 14:50:30	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> -0.608152 kdpm	 meas/pred -> 0.969421
            % mean([activityMeas   activityPred]) -> 23.172 kdpm
            % mean( activityMeas - activityPred ) -> -0.568011 kdpm
            %  std( activityMeas - activityPred ) -> 0.359638 kdpm
            % mean( activityMeas / activityPred ) -> 0.972374     
            %  std( activityMeas / activityPred ) -> 0.0181508     
            %                                   N -> 15
            %                            duration -> 910.343
            % 
            % mlcapintec.RefSourceCalibration.plotRefSourceStability('68Ge')
            % 
            % datetime -> 05-Oct-2018 10:42:10	 fileprefix -> CCIRRadMeasurements 2018oct5	 meas - pred -> 3.37561 kdpm	 meas/pred -> 1.0357
            % datetime -> 05-Oct-2018 18:00:19	 fileprefix -> CCIRRadMeasurements 2018oct5	 meas - pred -> 2.23561 kdpm	 meas/pred -> 1.02364
            % datetime -> 12-Sep-2018 13:58:25	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> 1.08507 kdpm	 meas/pred -> 1.01081
            % datetime -> 12-Sep-2018 14:09:40	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> 1.48507 kdpm	 meas/pred -> 1.01479
            % datetime -> 12-Sep-2018 14:23:23	 fileprefix -> CCIRRadMeasurements 2018sep12	 meas - pred -> 1.78507 kdpm	 meas/pred -> 1.01778
            % mean([activityMeas   activityPred]) -> 99.0674 kdpm
            % mean( activityMeas - activityPred ) -> 1.99329 kdpm
            %  std( activityMeas - activityPred ) -> 0.879775 kdpm
            % mean( activityMeas / activityPred ) -> 1.02054     
            %  std( activityMeas / activityPred ) -> 0.00968142     
            %                                   N -> 5
            %                            duration -> 23.168
        end
        function test_RefSourceCalibration(this)
            import mlcapintec.*;
            r = RefSourceCalibration('radMeas', this.radMeas);
            disp(r)
            
            % DEPRECATED
            %r.screenInvEfficiency(  'refSource', this.refSources(2));
            %r.screenInvEfficiencies('refSource', this.refSources(2));
        end        
        function test_SensitivityCalibration_invEfficiencyf(this)
            import mlcapintec.SensitivityCalibration
            
            % from CCIRRadMeasurements 2017sep6.numbers, Twilite Calibration, WELL COUNTER;
            % assessing measured activities in kdpm
            this.verifyEqual( ...
                4544.57*SensitivityCalibration.invEfficiencyf(4544.57), 4829.43, 'RelTol', 1e-4)
            this.verifyEqual( ...
                1642.06*SensitivityCalibration.invEfficiencyf(1642.06), 1640.41, 'RelTol', 1e-4)
            this.verifyEqual( ...
                2002.56*SensitivityCalibration.invEfficiencyf(2002.56), 2004.82, 'RelTol', 1e-4)
        end        
        function test_SensitivityCalibration_plot(~)
            rm = mlpet.CCIRRadMeasurements.createFromDate(mlcapintec.SensitivityCalibration.BEST_DATETIME);
            obj = mlcapintec.SensitivityCalibration('radMeas', rm);
            plot(copy(obj), 'model', 'none')
            plot(copy(obj), 'model', 'polynomial')
            plot(copy(obj), 'model', 'regressionLearner')
        end
        function test_SensitivityCalibration_table(~)
            rm = mlpet.CCIRRadMeasurements.createFromDate(mlcapintec.SensitivityCalibration.BEST_DATETIME);
            obj = mlcapintec.SensitivityCalibration('radMeas', rm);
            disp(table(copy(obj), 'model', 'none'))
            disp(table(copy(obj), 'model', 'polynomial'))
            disp(table(copy(obj), 'model', 'regressionLearner'))
        end
        function test_CapracCalibration(this)   
            import mlcapintec.CapracCalibration
            
            this.verifyEqual( ...
                CapracCalibration.invEfficiencyf('mass', 1,   'ge68', 1000), 1.0675, 'RelTol', 1e-4)
            
            this.verifyEqual( ...
                CapracCalibration.invEfficiencyf('mass', 0.1, 'ge68', 1000), 0.88772, 'RelTol', 1e-4)
            this.verifyEqual( ...
                CapracCalibration.invEfficiencyf('mass', 2,   'ge68', 1000), 1.40467, 'RelTol', 1e-4)
            this.verifyEqual( ...
                CapracCalibration.invEfficiencyf('mass', 1,   'ge68', 1e2 ), 1.11241, 'RelTol', 1e-4)
            this.verifyEqual( ...
                CapracCalibration.invEfficiencyf('mass', 1,   'ge68', 1e4 ), 1.34753, 'RelTol', 1e-4)            
            this.verifyEqual( ...
                CapracCalibration.invEfficiencyf('mass', 1,   'ge68', 1000, 'solvent', 'blood' ), 1.05897, 'RelTol', 1e-4)
            this.verifyEqual( ...
                CapracCalibration.invEfficiencyf('mass', 1,   'ge68', 1000, 'solvent', 'plasma'), 1.06289, 'RelTol', 1e-4)
        end
        function test_calibrationAvailable(this)
            obj = mlcapintec.CapracCalibration.createFromSession(this.session);
            this.verifyEqual(obj.calibrationAvailable, true)
        end
        function test_invEfficiencyf_isrow(this)
            obj = mlcapintec.CapracCalibration.createFromSession(this.session);
            o = ones(10, 1);
            this.verifyTrue(isrow(obj.invEfficiencyf('mass', o, 'ge68', o)))
        end
	end

 	methods (TestClassSetup)
		function setupCapracCalibration(this)
            this.session = mlraichle.SessionData.create('CCIR_00559/ses-E262767/FDG_DT20181005142531.000000-Converted-AC');
            this.radMeas = mlpet.CCIRRadMeasurements.createFromSession(this.session);
            this.refSources = mlpet.DeviceKit.createReferenceSources('session', this.session);
 		end
	end

 	methods (TestMethodSetup)
		function setupCapracCalibrationTest(this)
 			this.testObj = []; % mlcapintec.CapracCalibration(this.radMeas);
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

 
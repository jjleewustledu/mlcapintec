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
        scan
        session
 		testObj
 	end

	methods (Test)
        function test_ctor(this)
        end
        function test_apertureCal(this)
            import mlcapintec.*;
            a = ApertureCalibration(this.radMeas);
            a.selfCalibrate;
            a.screenInvEfficiency
        end
        function test_sensitivityCal(this)
            import mlcapintec.*;
            s = SensitivityCalibration(this.radMeas);
            s.selfCalibrate;
            s.screenInvEfficiency
        end
        function test_refSourceCal(this)
            import mlcapintec.*;
            r = RefSourceCalibration(this.radMeas);
            r.selfCalibrate;
            r.screenInvEfficiencies('refSource', this.refSources(2));
            r.screenInvEfficiency(  'refSource', this.refSources(2));
        end
        function test_selfCalibrate(this)
            this.testObj.selfCalibrate;
        end        
        
        function test_predictActivity(this)
        end
        function test_predictInvEff(this)
        end
        function test_predictSpecificActivity(this)
        end
	end

 	methods (TestClassSetup)
		function setupCapracCalibration(this)
            import mlraichle.*;
            this.session = MockSession( ...
                'project', 'CCIR_00559', 'subject', 'NP995-24', 'session', 'NP995-24_V1');
            this.scan = MockScan( ...
                'project', 'CCIR_00559', 'subject', 'NP995-24', 'session', this.session, ...
                'Assessor', '', ...
                'resource', 'RawData', ...
                'tags', {'Head_MRAC_PET_5min'});
            this.radMeas = mlpet.CCIRRadMeasurements.createBySession(this.session);
            this.refSources = mlpet.InstrumentKit.createReferenceSources('session', this.session);
 		end
	end

 	methods (TestMethodSetup)
		function setupCapracCalibrationTest(this)
 			this.testObj = mlcapintec.CapracCalibration(this.radMeas);
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


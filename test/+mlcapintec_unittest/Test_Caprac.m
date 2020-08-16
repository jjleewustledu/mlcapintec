classdef Test_Caprac < matlab.unittest.TestCase
	%% TEST_CAPRAC 

	%  Usage:  >> results = run(mlcapintec_unittest.Test_Caprac)
 	%          >> result  = run(mlcapintec_unittest.Test_Caprac, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:42
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlcapintec/test/+mlcapintec_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        doseAdminDatetimeFDG = datetime(2016,9,23,12,43,52, 'TimeZone', 'America/Chicago');
        ccirRadMeasurementsDir = fullfile(getenv('HOME'), 'Documents/private')
        mand
 		registry
        sessd
        sessp = 'CCIR_00754/ses-E191506/FDG_DT20160923124357.000000-Converted-AC'
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlcapintec.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_ctor(this)
            this.verifyClass(this.testObj, 'mlcapintec.Caprac');
            this.verifyEqual(this.testObj.doseAdminDatetime, this.doseAdminDatetimeFDG);
            this.verifyEqual(this.testObj.dt, 1);
            this.verifyEqual(this.testObj.times(10), 45);
            this.verifyEqual(this.testObj.isotope, '18F');
            this.verifyEqual(this.testObj.counts(10), 9.545187860008738e+03, 'RelTol', 1e-9);
            this.verifyEqual(this.testObj.specificActivity(10), 3.081822989356473e+04, 'RelTol', 1e-9);
            this.verifyEqual(this.testObj.invEfficiency, 1);
            this.verifyEqual(this.testObj.W, 1);
        end
        function test_plot(this)
            this.testObj.invEfficiency = 1;
            plot(this.testObj, '.');
            plotCounts(this.testObj, '.');
            this.testObj.invEfficiency = 2;
            plotSpecificActivity(this.testObj, '.');
        end
        function test_datetime(this)
            dt_ = this.testObj.datetime;
            this.verifyEqual(dt_(1),  datetime(2016,9,23,12,44,0, 'TimeZone', 'America/Chicago'));
            this.verifyEqual(dt_(10), datetime(2016,9,23,12,44,45,'TimeZone', 'America/Chicago'));
            this.verifyEqual(length(dt_), 32);
        end
        function test_timesDrawn(this)
            this.verifyEqual(this.testObj.times(1), 0);
            this.verifyEqual(this.testObj.times(10), 45);
            this.verifyEqual(length(this.testObj.times), 32);
        end
        function test_counts(this)
            this.verifyEqual(this.testObj.counts(1),  1.190209966099220,     'RelTol', 1e-12);
            this.verifyEqual(this.testObj.counts(10), 9.545187860008738e+03, 'RelTol', 1e-12);
            this.verifyEqual(length(this.testObj.counts), 32);
        end
        function test_specificActivity(this)
            this.verifyEqual(this.testObj.specificActivity(1),  3.019649889306200,     'RelTol', 1e-12);
            this.verifyEqual(this.testObj.specificActivity(10), 3.081822989356473e+04, 'RelTol', 1e-12);
            this.verifyEqual(this.testObj.specificActivity(32), 1.497500815599805e+03, 'RelTol', 1e-12);
            this.verifyEqual(length(this.testObj.specificActivity), 32);
        end
        function test_correctedSpecificActivity(this)
            this.testObj = this.testObj.correctedActivities(0);
            this.verifyEqual(this.testObj.specificActivity(1),  3.0196498893062001,    'RelTol', 1e-12);
            this.verifyEqual(this.testObj.specificActivity(10), 3.096452668003811e+04, 'RelTol', 1e-12);
            this.verifyEqual(this.testObj.specificActivity(32), 2.185454885488859e+03, 'RelTol', 1e-12);
            this.verifyEqual(length(this.testObj.specificActivity), 32);
        end
	end

 	methods (TestClassSetup)
		function setupCaprac(this)
 			import mlcapintec.*;                    
            setenv('CCIR_RAD_MEASUREMENTS_DIR', this.ccirRadMeasurementsDir);
            this.sessd = mlraichle.SessionData.create(this.sessp);
            this.mand = mlpet.CCIRRadMeasurements.createFromSession(this.sessd);
 			this.testObj_ = Caprac( ...
                'fqfilename', this.sessd.CCIRRadMeasurements, ...
                'sessionData', this.sessd, ...
                'manualData', this.mand, ...
                'isotope', '18F', ...
                'doseAdminDatetime', this.doseAdminDatetimeFDG);
 		end
	end

 	methods (TestMethodSetup)
		function setupCapracTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


classdef Test_CapracData < matlab.unittest.TestCase
	%% TEST_CAPRACDATA 

	%  Usage:  >> results = run(mlcapintec_unittest.Test_CapracData)
 	%          >> result  = run(mlcapintec_unittest.Test_CapracData, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 21-Oct-2018 22:31:49 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/test/+mlcapintec_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        datetimeF
        doseAdminDatetimeFDG = datetime(2019,5,23,13,30,12, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
 		registry
        sesd
        sesf = 'CCIR_00559/ses-E03056/FDG_DT20190523132832.000000-Converted-AC'
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
            o = this.testObj;
            disp(o)
            
            this.verifyEqual(o.branchingRatio, 0.967)
            this.verifyEqual(o.datetimeForDecayCorrection, this.doseAdminDatetimeFDG)
            this.verifyFalse(o.decayCorrected)
            this.verifyEqual(o.halflife, 6586.236)
            this.verifyEqual(o.isotope, '18F')
            this.verifyEqual(o.tracer, 'FDG')
            this.verifyEqual(o.datetime0, this.doseAdminDatetimeFDG)
            this.verifyEqual(o.datetimeF, this.datetimeF)
            this.verifyEqual(o.datetimeInterpolants, this.doseAdminDatetimeFDG:seconds(1):this.datetimeF)
            this.verifyEqual(o.datetimeMeasured, this.doseAdminDatetimeFDG)
            this.verifyEqual(o.datetimeWindow, duration(0, 59, 57))
            this.verifyEqual(o.datetimes(1), this.doseAdminDatetimeFDG)
            this.verifyEqual(o.datetimes(end), this.datetimeF)
            this.verifyEqual(o.dt, 1)
            this.verifyEqual(o.index0, 1)
            this.verifyEqual(o.indexF, 39)
            this.verifyEqual(o.indices, 1:39)
            this.verifyEqual(o.taus, [3 4 3 4 4 4 3 5 5 4 5 4 4 3 3 5 4 3 4 4 3 3 6 3 2 3 5 3 3 4 4 3 297 180 300 300 1800 600 600])
            this.verifyEqual(o.time0, 0)
            this.verifyEqual(o.timeF, 3597)
            this.verifyEqual(o.times, [0 3 7 10 14 18 22 25 30 35 39 44 48 52 55 58 63 67 70 74 78 81 84 90 93 95 98 103 106 109 113 117 120 417 597 897 1197 2997 3597])
            this.verifyEqual(o.timeInterpolants, 0:3597)
            this.verifyEqual(o.timeWindow, 3597)
        end
        function test_plot(this)
            o = this.testObj;
            plot(o)
            plot(o, ...
                'this.times()', ...
                'this.activity()');
            plot(o, ...
                'this.times()', ...
                'this.activityDensity(''decayCorrected'', true, ''index0'', 1, ''indexF'', 39)');
            plot(o, ...
                'this.times()', ...
                'this.countRate()');
        end
        function test_shiftWorldlines(this)
 			o = this.testObj;
            plot(o)
            o.datetimeForDecayCorrection = this.doseAdminDatetimeFDG;
            o.shiftWorldlines(-120);
            plot(o);
            title('Test\_CapracData.test\_shiftWorldlines()')
        end
	end

 	methods (TestClassSetup)
		function setupCapracData(this)
            this.datetimeF = this.doseAdminDatetimeFDG + seconds(3597);
 		end
	end

 	methods (TestMethodSetup)
		function setupCapracDataTest(this)
 			import mlcapintec.*;
            this.sesd = mlraichle.SessionData.create(this.sesf);
 			this.testObj = CapracData.createFromSession(this.sesd);
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

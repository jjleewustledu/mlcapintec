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
            plot(this.testObj)
            plot(this.testObj, ...
                'this.times()', ...
                'this.activityDensity(''decayCorrected'', true, ''index0'', 1, ''indexF'', 39)');
        end
        function test_activity(this)
            plot(this.testObj, ...
                'this.datetime()', ...
                'this.activity()');
        end
        function test_activity_kdpm(this)
            plot(this.testObj, ...
                'this.datetime()', ...
                'this.activity_kdpm()');
        end
        function test_activityDensity(this)
            o = this.testObj;
            this.verifyEqual(o.datetimes(1), datetime(2019,5,23,13,30,12, 'TimeZone', 'America/Chicago'))
            this.verifyEqual(o.datetimes(end), datetime(2019,5,23,14,30,9, 'TimeZone', 'America/Chicago'))
            this.verifyEqual(o.activityDensity, ...
                [13.6974494954153 35.373279459104 28.5684544205026 52.9932617222406 99.9766823338598 17658.2897903035 127627.633370223 229549.693209493 201718.717359553 114389.713036904 76117.512427755 67437.0742783745 54881.8644873828 46733.7412402327 43467.0404508263 41584.8162962794 38902.4605526062 36771.6103008218 35505.207733973 34123.7329534629 34382.6470586787 33164.30136235 32136.8050218769 31571.4049660013 30131.1528286555 27977.0470876852 28263.9860034672 28505.2895856289 27953.1946876117 26907.6967635457 26406.0514370121 25682.8069325953 24949.8719423234 10716.9871403955 7459.07627009617 4715.19555051277 2968.16175640285 846.472388903424 604.690846036385], ...
                'RelTol', 1e-10)
            plot(this.testObj, ...
                'this.datetime()', ...
                'this.activityDensity()');
        end
        function test_countRate(this)
            plot(this.testObj, ...
                'this.datetime()', ...
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

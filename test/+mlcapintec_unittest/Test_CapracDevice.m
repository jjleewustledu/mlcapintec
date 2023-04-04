classdef Test_CapracDevice < matlab.unittest.TestCase
	%% TEST_CAPRACDEVICE 

	%  Usage:  >> results = run(mlcapintec_unittest.Test_CapracDevice)
 	%          >> result  = run(mlcapintec_unittest.Test_CapracDevice, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 21-Oct-2018 22:31:45 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/test/+mlcapintec_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        datetimeF
        doseAdminDatetimeFDG = datetime(2019,5,23,13,30,12, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        radMeas        
 		registry
        sesd
        sesf = 'CCIR_00559/ses-E03056/FDG_DT20190523132832.000000-Converted-AC'
        sessd
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
            this.verifyClass(this.sessd, 'mlraichle.SessionData');         
            this.verifyClass(this.radMeas, 'mlpet.CCIRRadMeasurements');
            this.verifyClass(this.testObj, 'mlcapintec.CapracDevice');
            disp(this.testObj)
        end
        function test_logger(this) 
        end
        function test_plot(this)
            plot(this.testObj)
        end
        function test_radMeasurements(this)
            rm = this.testObj.radMeasurements;
            this.verifyClass(rm, 'mlpet.CCIRRadMeasurements')
            this.verifyTrue(isprop(rm, 'countsFdg'))
            this.verifyTrue(isprop(rm, 'laboratory'))
            this.verifyTrue(isprop(rm, 'mMR'))
            this.verifyTrue(isprop(rm, 'phantom'))
            this.verifyTrue(isprop(rm, 'clocks'))
            this.verifyTrue(isprop(rm, 'pmod'))
            this.verifyTrue(isprop(rm, 'wellCounter'))
            this.verifyTrue(isprop(rm, 'twilite'))
            this.verifyTrue(isprop(rm, 'countsOcOo'))
            this.verifyTrue(isprop(rm, 'capracHeader'))
            this.verifyTrue(isprop(rm, 'doseCalibrator'))
            this.verifyTrue(isprop(rm, 'tracerAdmin'))
            disp(rm)
        end        
        function test_background(this)
            this.verifyClass(this.testObj.background, 'table')
            b = this.testObj.background;
            time = datetime(2019,5,23,9,30,36, 'TimeZone', 'America/Chicago');
            counts = 164;
            countsSE = 12.8;
            entered = true;
            this.verifyEqual(b(1,:), table(time, counts, countsSE, entered))
            disp(b)
        end
        function test_invEfficiencyf(this)
            import mlcapintec.CapracDevice
            
            this.verifyEqual( ...
                CapracDevice.invEfficiencyf('mass', 1,   'ge68', 1000), 1.03765440103042,  'RelTol', 1e-4)            
            this.verifyEqual( ...
                CapracDevice.invEfficiencyf('mass', 0.1, 'ge68', 1000), 0.867726471704529, 'RelTol', 1e-4)
            this.verifyEqual( ...
                CapracDevice.invEfficiencyf('mass', 2,   'ge68', 1000), 1.32604588866197,  'RelTol', 1e-4)
            this.verifyEqual( ...
                CapracDevice.invEfficiencyf('mass', 1,   'ge68', 1e2 ), 1.08129630715437,  'RelTol', 1e-4)
            this.verifyEqual( ...
                CapracDevice.invEfficiencyf('mass', 1,   'ge68', 1e4 ), 1.30983972848753,  'RelTol', 1e-4)            
            this.verifyEqual( ...
                CapracDevice.invEfficiencyf('mass', 1,   'ge68', 1000, 'solvent', 'water' ), 1.04602429838361,  'RelTol', 1e-4)
            this.verifyEqual( ...
                CapracDevice.invEfficiencyf('mass', 1,   'ge68', 1000, 'solvent', 'plasma'), 1.041492870743203, 'RelTol', 1e-4)   
            this.verifyEqual( ...
                CapracDevice.invEfficiencyf('mass', 1,   'ge68', 1000, 'solvent', 'blood' ), 1.037654401030424, 'RelTol', 1e-4)
        end
        function test_activity(this)
            o = this.testObj;
            plot(o, 'this.datetime', 'this.activity')
        end
        function test_activityDensity(this)
            o = this.testObj;
            this.verifyEqual(o.datetimes(1), datetime(2019,5,23,13,30,12, 'TimeZone', 'America/Chicago'))
            this.verifyEqual(o.datetimes(end), datetime(2019,5,23,14,30,9, 'TimeZone', 'America/Chicago'))
            this.verifyEqual(o.times, ...
                [0 3 7 10 14 18 22 25 30 35 39 44 48 52 55 58 63 67 70 74 78 81 84 90 93 95 98 103 106 109 113 117 120 417 597 897 1197 2997 3597])
            this.verifyEqual(o.activityDensity, ...
                [15.7231339417783 40.0670951423858 32.7896589986613 60.9033324985914 115.390827456407 20247.5870083001 138101.363561975 247624.893301051 219962.735811158 123800.355195601 84547.8333286971 74641.7780423665 61033.7705200579 51488.086840046 48137.398517549 45853.6272536275 43105.9076185098 40588.4399463862 39532.0074392734 37376.951543845 38029.7572601973 36896.5536596196 35837.3996944633 35239.9976922434 33563.3578174873 31172.6742405234 31661.2958727327 31726.6836574803 31190.0410893731 29736.9838758955 29345.5491772129 28612.6204028212 28087.9993320967 12488.6629201451 8478.08886746032 5324.32339588189 3353.30521211569 945.745212317361 665.76566052086], ...
                'RelTol', 1e-10)
            plot(o, 'this.datetime', 'this.activityDensity')
        end
        function test_countRate(this)
            o = this.testObj;
            plot(o, 'this.datetime', 'this.countRate')
        end
	end

 	methods (TestClassSetup)
		function setupCapracDevice(this)
            this.datetimeF = this.doseAdminDatetimeFDG + seconds(3597);
            this.sessd = mlraichle.SessionData.create(this.sesf);
            this.radMeas = mlpet.CCIRRadMeasurements.createFromSession(this.sessd);
 		end
	end

 	methods (TestMethodSetup)
		function setupCapracDeviceTest(this)
 			this.testObj = mlcapintec.CapracDevice.createFromSession(this.sessd);
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

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
        radMeas
        refSources
 		registry
        scan
        session
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlcapintec.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_screenInvEfficencies(this)
            this.testObj.screenInvEfficiencies('refSource', this.refSources(1));
            this.testObj.screenInvEfficiencies('refSource', this.refSources(2));
            this.testObj.screenInvEfficiencies('refSource', this.refSources(3));
        end
        function test_screenInvEfficency(this)
            this.testObj.screenInvEfficiency('refSource', this.refSources(1));
            this.testObj.screenInvEfficiency('refSource', this.refSources(2));
            this.testObj.screenInvEfficiency('refSource', this.refSources(3));
        end
        function test_invEfficiency(this)
        end
        function test_ctor(this)
            this.verifyClass(this.session, 'mlraichle.MockSession');
            this.verifyClass(this.scan, 'mlraichle.MockScan');            
            this.verifyClass(this.radMeas, 'mlraichle.CCIRRadMeasurements');
            this.verifyClass(this.refSources, 'mlpet.ReferenceSource');
            this.verifyClass(this.testObj, 'mlcapintec.CapracDevice');
            this.testObj
        end
        function test_logger(this) 
        end
        function test_radMeasurements(this)
        end        
        function test_background(this)
        end
        function test_hasReferenceSourceMeasurements(this)
        end
        function test_referenceSources(this)
        end
        function test_calibrateDevice(this)
            %this.testObj.calibrateDevice
        end
        function test_makeMeasurements(this)
        end
	end

 	methods (TestClassSetup)
		function setupCapracDevice(this)
            import mlraichle.*;
            this.session = MockSession( ...
                'project', 'CCIR_00559', 'subject', 'NP995-24', 'session', 'NP995-24_V1');
            this.scan = MockScan( ...
                'project', 'CCIR_00559', 'subject', 'NP995-24', 'session', this.session, ...
                'Assessor', '', ...
                'resource', 'RawData', ...
                'tags', {'Head_MRAC_PET_5min'});
            this.radMeas = CCIRRadMeasurements.createFromSession(this.session);
            this.refSources = mlpet.DeviceKit.createReferenceSources('session', this.session);
 		end
	end

 	methods (TestMethodSetup)
		function setupCapracDeviceTest(this)
 			this.testObj = mlcapintec.CapracDevice( ...
                'radMeasurements', this.radMeas, ...
                'referenceSources', this.refSources);
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


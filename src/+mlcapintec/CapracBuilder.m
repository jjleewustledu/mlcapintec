classdef CapracBuilder < handle & mlpet.DeviceBuilder
	%% CAPRACBUILDER  

	%  $Revision$
 	%  was created 12-Dec-2017 16:32:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Dependent)
        datetime0 		
 	end

	methods 
        
        %% GET
        
        function g = get.datetime0(this)
            g = this.datetime0_;
        end
        
        %%
        
        function this = buildCalibrator(this)
            this.product_ = mlcapintec.Caprac( ...
                'sessionData', this.sessionData_, ...
                'doseAdminDatetime', this.manualData_.mMRDatetime, ...
                'isotope', '18F', ...
                'table', this.manualData.capracCalibration);
            this.calibrator_ = this.product_;
        end
        function this = buildNativeFdg(this)
            this.product_ = mlcapintec.Caprac( ...
                'sessionData', this.sessionData_, ...
                'doseAdminDatetime', this.manualData_.tracerAdmin.TrueAdmin_Time_Hh_mm_ss('[18F]DG'), ...
                'isotope', '18F', ...
                'tableData', this.manualData_.fdg);
        end
        function this = buildNativeOo(this)
            this.product_ = mlcapintec.Caprac( ...
                'sessionData', this.sessionData_, ...
                'doseAdminDatetime', this.manualData_.tracerAdmin.TrueAdmin_Time_Hh_mm_ss('O[15O]'), ...
                'isotope', '15O', ...
                'tableData', this.manualData_.oo);
        end
        function this = buildCalibrated(this)
            this = this.buildCalibrator;
            this.calibrator_ = this.calibrator_.correctedActivities(this.manualData_.mMRDatetime);
            % TODO:  refactor psa manipulations into an abstraction.
            psa = this.calibrator_.decayCorrection.correctedActivities( ...
                  this.manualData_.phantomSpecificActivity, this.manualData_.mMRDatetime);
            this.calibrator_.invEfficiency = psa / this.calibrator_.specificActivity;
            
            this = this.buildNative;
            this.product_.invEfficiency = this.calibrator_.invEfficiency;
        end
        
        function this = readMeasurements(this)
        end
        function this = propagateEfficiencies(this)
        end
		  
 		function this = CapracBuilder(varargin)
 			%% CAPRACBUILDER  
            %  @param named datetime0 for target Caprac AIF.          
            
            this = this@mlpet.DeviceBuilder(varargin{:}); 
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'datetime0', NaT, @isdatetime);
            parse(ip, varargin{:});            
            this.datetime0_ = ip.Results.datetime0; 	
 		end
 	end 

    %% PROTECTED
    
    properties (Access = protected)
        datetime0_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


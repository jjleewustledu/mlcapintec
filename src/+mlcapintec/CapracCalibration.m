classdef CapracCalibration < handle & mlpet.AbstractCalibration
	%% CAPRACCALIBRATION  

	%  $Revision$
 	%  was created 06-Nov-2018 14:46:31 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.

	methods 
        
        %%
        
        function a    = predictActivity(this, varargin)
            a = this.refSourceCal_.predictActivity( ...
                 this.sensitivityCal_.predictActivity( ...
                 this.apertureCal_.predictActivity(varargin{:}))); 
        end
        function ie   = predictInvEff(this, varargin)
            ie = this.refSourceCal_.predictInvEff(varargin{:}) .* ...
                 this.sensitivityCal_.predictInvEff(varargin{:}) .* ...
                 this.apertureCal_.predictInvEff(varargin{:}); 
        end
        function a    = predictSpecificActivity(this, varargin)
            a = this.refSourceCal_.predictSpecificActivity( ...
                 this.sensitivityCal_.predictSpecificActivity( ...
                 this.apertureCal_.predictSpecificActivity(varargin{:}))); 
        end
        function this = selfCalibrate(this)
            import mlcapintec.*;
            this.apertureCal_ = ApertureCalibration(this.radMeasurements_);
            this.apertureCal_.selfCalibrate;
            this.sensitivityCal_ = SensitivityCalibration(this.radMeasurements_);
            this.sensitivityCal_.selfCalibrate;
            this.refSourceCal_ = RefSourceCalibration(this.radMeasurements_);
            this.refSourceCal_.selfCalibrate;
            this.calibrator_ = this;
        end
		  
 		function this = CapracCalibration(varargin)
 			%% CAPRACCALIBRATION
            
            this = this@mlpet.AbstractCalibration(varargin{:});
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        apertureCal_
        sensitivityCal_
        refSourceCal_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


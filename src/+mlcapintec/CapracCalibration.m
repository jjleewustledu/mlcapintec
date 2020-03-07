classdef CapracCalibration < handle & mlpet.AbstractCalibration
	%% CAPRACCALIBRATION  

	%  $Revision$
 	%  was created 06-Nov-2018 14:46:31 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
    
    properties (Dependent)
        invEfficiency
    end
    
    methods (Static)
        function buildCalibration()
            mlcapintec.ApertureCalibration.buildCalibration()
            mlcapintec.SensitivityCalibration.buildCalibration()
        end
        function this = createBySession(varargin)
            %% CREATEBYSESSION
            %  @param required sessionData is an mlpipeline.ISessionData.
            %  See also:  mlpet.CCIRRadMeasurements.createBySession().
            
            rad = mlpet.CCIRRadMeasurements.createBySession(varargin{:});
            this = mlcapintec.CapracCalibration.createByRadMeasurements(rad);
        end
        function this = createByRadMeasurements(rad)
            %% CREATEBYRADMEASUREMENTS
 			%  @param required radMeasurements is mlpet.CCIRRadMeasurements.

            assert(isa(rad, 'mlpet.CCIRRadMeasurements'))
            this = mlcapintec.CapracCalibration(rad);
        end
        function ie = invEfficiencyf(varargin)
            import mlcapintec.ApertureCalibration
            import mlcapintec.SensitivityCalibration
            
            ip = inputParser;
            addParameter(ip, 'mass', NaN, @isnumeric)
            addParameter(ip, 'ge68', NaN, @isnumeric)
            addParameter(ip, 'solvent', 'water', @ischar)
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            ie = ApertureCalibration.invEfficiencyf(ipr.mass, 'solvent', ipr.solvent) .* ...
                 SensitivityCalibration.invEfficiencyf(ipr.ge68);            
        end     
    end
    
	methods 	
        
        %% GET
        
        function g = get.invEfficiency(~) %#ok<STOUT>
            error('mlcapintec:RuntimeError', 'CapracCalibration.invEfficiency:  use invEfficiencyf()')
        end
    end 
    
    %% PROTECTED
    
    methods (Static, Access = protected) 
    end
    
    methods (Access = protected)
 		function this = CapracCalibration(varargin)
            this = this@mlpet.AbstractCalibration(varargin{:});
 		end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


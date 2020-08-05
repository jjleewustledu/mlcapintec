classdef CapracCalibration < handle & mlpet.AbstractCalibration
	%% CAPRACCALIBRATION  

	%  $Revision$
 	%  was created 06-Nov-2018 14:46:31 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
    
    properties (Dependent)
        calibrationAvailable
        invEfficiency
    end
    
    methods (Static)
        function buildCalibration()
            mlcapintec.ApertureCalibration.buildCalibration()
            mlcapintec.SensitivityCalibration.buildCalibration()
        end
        function this = createFromSession(sesd, varargin)
            %% CREATEFROMSESSION
            %  @param required sessionData is an mlpipeline.ISessionData.
            %  @param optional offset is numeric & searches for alternative SessionData.
            %  See also:  mlpet.CCIRRadMeasurements.createFromSession().
            
            import mlcapintec.CapracCalibration
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sesd', @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'offset', 1, @isnumeric)
            addParameter(ip, 'radMeasurements', [], @(x) isa(x, 'mlpet.RadMeasurements') || isempty(x))
            parse(ip, sesd, varargin{:})
            ipr = ip.Results;
            offset = ipr.offset;
            
            try
                if ~isempty(ipr.radMeasurements)
                    rad = ipr.radMeasurements;
                else
                    rad = mlpet.CCIRRadMeasurements.createFromSession(sesd, 'exactMatch', false);
                end
                this = CapracCalibration('radMeas', rad);
                
                % get caprac calibration from most time-proximal calibration measurements
                if ~this.calibrationAvailable
                    error('mlcapintec:ValueError', 'CapracCalibration.calibrationAvailable -> false')
                end
            catch ME
                handwarning(ME)
                [sesd1,offset] = sesd.findProximalSession2(sesd, offset);
                varargin1 = [varargin {'offset', offset+1}];
                this = CapracCalibration.createFromSession(sesd1, varargin1{:});             
            end
        end
        function ie = invEfficiencyf(varargin)
            import mlcapintec.ApertureCalibration
            import mlcapintec.SensitivityCalibration
            
            ip = inputParser;
            addParameter(ip, 'ge68', NaN, @isnumeric)
            addParameter(ip, 'mass', NaN, @isnumeric)
            addParameter(ip, 'solvent', 'water', @ischar)
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            ie = ApertureCalibration.invEfficiencyf(ascol(ipr.mass), 'solvent', ipr.solvent) .* ...
                 SensitivityCalibration.invEfficiencyf(ascol(ipr.ge68));
            ie = asrow(ie);
        end
    end
    
	methods 	
        
        %% GET
        
        function g = get.calibrationAvailable(this)
            %% @return logical scalar
            
            rm = this.radMeasurements_;
            rowSelect = this.isotopeSelection();
            timeCounted = rm.wellCounter.TIMECOUNTED_Hh_mm_ss(rowSelect);            
            if ~any(isnice(timeCounted))
                g = false;
                return
            end                
            mass = rm.wellCounter.MassSample_G(rowSelect);
            if ~any(isnice(mass(isnice(timeCounted))))
                g = false;
                return
            end
            ge68 = rm.wellCounter.Ge_68_Kdpm(rowSelect);
            if ~any(isnice(ge68(isnice(timeCounted))))
                g = false;
                return
            end
            g = true;       
        end
        function g = get.invEfficiency(~) %#ok<STOUT>
            error('mlcapintec:RuntimeError', 'CapracCalibration.invEfficiency:  use invEfficiencyf()')
        end
        
        %%
        
        function a = activity(this, varargin)
            %% Bq 
            %  @param mass in g
            %  @param ge68 in kdpm
            %  @param solvent
            
            ip = inputParser;
            addParameter(ip, 'mass', NaN, @isnumeric)
            addParameter(ip, 'ge68', NaN, @isnumeric)
            addParameter(ip, 'solvent', 'water', @ischar)
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            a = ascol(this.activityDensity);
            switch ipr.solvent
                case 'water'
                    a = a .* ipr.mass / this.WATER_DENSITY; % Bq
                case 'blood'
                    a = a .* ipr.mass / this.WATER_DENSITY; % Bq
                case 'plasma'
                    a = a .* ipr.mass / this.WATER_DENSITY; % Bq
                otherwise
                    error('mlcapintec:NotImplementedError', ...
                        'CapracCalibration.activityDensity().ipr.solvent->%s', ipr.solvent)
            end 
            a = asrow(a);
        end
        function a = activityDensity(this, varargin)
            %% Bq/mL
            %  @param mass
            %  @param ge68
            %  @param solvent
            
            ip = inputParser;
            addParameter(ip, 'mass', NaN, @isnumeric)
            addParameter(ip, 'ge68', NaN, @isnumeric)
            addParameter(ip, 'solvent', 'water', @ischar)
            parse(ip, varargin{:});
            ipr = ip.Results;
            ipr.ge68 = asrow(ipr.ge68);
            ipr.mass = asrow(ipr.mass);
        
            ie = this.invEfficiencyf(varargin{:});
            switch ipr.solvent
                case 'water'
                    a = (1e3/60) * this.WATER_DENSITY * ie .* ipr.ge68 ./ ipr.mass; % Bq/mL
                case 'blood'
                    a = (1e3/60) * this.BLOOD_DENSITY * ie .* ipr.ge68 ./ ipr.mass; % Bq/mL
                case 'plasma'
                    a = (1e3/60) * this.PLASMA_DENSITY * ie .* ipr.ge68 ./ ipr.mass; % Bq/mL
                otherwise
                    error('mlcapintec:NotImplementedError', ...
                        'CapracCalibration.activityDensity().ipr.solvent->%s', ipr.solvent)
            end  
            a = asrow(a);
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

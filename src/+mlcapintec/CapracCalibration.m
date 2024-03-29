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
        function construct_caprac_stats()
            %% CONSTRUCT_CAPRAC_STATS iterates over CCIRRadMeasurements*.xlsx to generate stats for the well-counter.
            %  @return specific activity for aq. [18F]DG measuremnts in Bq/mL with all Caprac calibrations and
            %          decay-adjusted to time of phantom scanning.

            %% Version $Revision$ was created $Date$ by $Author$,
            %% last modified $LastChangedDate$ and checked into repository $URL$,
            %% developed on Matlab 9.7.0.1296695 (R2019b) Update 4.  Copyright 2020 John Joowon Lee.

            HALFLIFE = 6586.272; % [18F] / s
            WATER_DENSITY = 0.9982; % g / mL

            cd(getenv('CCIR_RAD_MEASUREMENTS_DIR'))
            for xlsx = globT('CCIRRadMeasurements*.xlsx')
                crm = mlpet.CCIRRadMeasurements.createFromFilename(xlsx{1});
                clocks = crm.clocks;
                well = crm.wellCounter;
                mMR = crm.mMR;

                rowSelect = strcmp(well.TRACER, '[18F]DG') & ...
                    ~isnat(well.TIMECOUNTED_Hh_mm_ss) & ...
                    ~isnan(well.MassSample_G) & ...
                    ~isnan(well.Ge_68_Kdpm);
                dtime = seconds( ...
                    well.TIMECOUNTED_Hh_mm_ss(rowSelect) - ...
                    mMR{1, 'scanStartTime_Hh_mm_ss'} + ...
                    seconds(clocks{'mMR console', 'TimeOffsetWrtNTS____s'}));
                mass = well.MassSample_G(rowSelect);
                ge68 = well.Ge_68_Kdpm(rowSelect) .* 2.^(dtime/HALFLIFE);
                if isempty(mass) || isempty(ge68)
                    continue
                end
                ie = mlcapintec.ApertureCalibration.invEfficiencyf(mass) .* mlcapintec.SensitivityCalibration.invEfficiencyf(ge68);

                sa = (1e3/60) * ge68 .* ie * WATER_DENSITY ./ mass; % Bq/mL

                fprintf('########################################################################################################\n')
                fprintf('file:  %s\n', xlsx{1})
                fprintf('well stats:  mean %f, std %f (Bq/mL)\n\n', mean(sa), std(sa))
            end
        end
        function this = createFromSession(sesd, varargin)
            %% CREATEFROMSESSION
            %  @param required sessionData is an mlpipeline.ISessionData.
            %  @param exactMatch is logical.  Default is true.  If false, find proximal session & rad meas.
            %  See also:  mlpet.CCIRRadMeasurements.createFromSession().
            
            import mlcapintec.CapracCalibration
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sesd', @(x) isa(x, 'mlpipeline.ISessionData') || isa(x, 'mlpipeline.ImagingMediator'))
            addParameter(ip, 'radMeasurements', [], @(x) isa(x, 'mlpet.RadMeasurements') || isempty(x))
            addParameter(ip, 'exactMatch', true, @islogical)
            parse(ip, sesd, varargin{:})
            ipr = ip.Results;
            rad = ipr.radMeasurements;

            if ipr.exactMatch
                if isempty(rad)
                    rad = mlpet.CCIRRadMeasurements.createFromSession(sesd);
                end
                this = CapracCalibration('radMeas', rad);
                
                assert(this.calibrationAvailable, 'mlcapintec.CapracCalibration.calibrationAvailable->false')
            else
                if isempty(rad)
                    rad = mlpet.CCIRRadMeasurements.createFromSession(sesd);
                end
                this = CapracCalibration('radMeas', rad);

                offset = 0;
                while ~this.calibrationAvailable              
                    offset = offset + 1;
                    try
                        sesd1 = sesd.findProximal(offset);
                        rad1 = mlpet.CCIRRadMeasurements.createFromSession(sesd1);
                        this = CapracCalibration('radMeas', rad1);
                    catch ME
                        handwarning(ME)
                        if offset > 100
                            error('mlcapintec:RuntimeError', ...
                                'CapracCalibration.createFromSession.offset -> %g', offset)
                        end
                    end
                end
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
            %% Bq at time of measurement on Caprac
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
            %% Bq/mL at time of measurement on Caprac
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

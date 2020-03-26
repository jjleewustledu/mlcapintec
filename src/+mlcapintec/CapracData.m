classdef CapracData < handle & mlpet.AbstractTracerData
	%% CAPRACDATA  

	%  $Revision$
 	%  was created 07-Mar-2020 13:47:02 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent)
 		radMeasurements
        visibleVolume % vector for syringe containing whole blood
 	end
    
    methods (Static)
        function this = createFromSession(sesd)
            assert(isa(sesd, 'mlpipeline.ISessionData'))
            this = mlcapintec.CapracData( ...
                'isotope', sesd.isotope, ...
                'tracer', sesd.tracer, ...
                'datetimeMeasured', sesd.datetime);
        end
    end
    
    methods
        
        %% GET
        
        function g = get.radMeasurements(this)
            g = this.radMeasurements_;
        end
        function g = get.visibleVolume(this)
            mass = this.radMeasurements.countsFdg.MASSSAMPLE_G(this.countsFdgSelection);
            g = mass/mlcapintec.CapracCalibration.BLOOD_DENSITY;
        end
        
        %% 
        
        function [a,m] = activity(this, varargin)
            %% Bq for whole blood in syringes, without Caprac calibrations.
            %  See also mlcapintec.CapracDevice for implementation of calibrations.
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @return activity (Bq), mass (g).
            
            a = this.radMeasurements.countsFdg.Ge_68_Kdpm(this.countsFdgSelection)*1e3/60;
            m = this.radMeasurements.countsFdg.MASSSAMPLE_G(this.countsFdgSelection);     
            assert(all(size(a) == size(m)))
        end
        function [a,m] = activityDensity(this, varargin)
            %% Bq/mL for whole blood in syringes, without Caprac calibrations.
            %  See also mlcapintec.CapracDevice for implementation of calibrations.            
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @return activity density (Bq/mL), mass (g).
            
            ip = inputParser;
            addParameter(ip, 'decayCorrected', false, @islogical)
            addParameter(ip, 'datetimeForDecayCorrection', NaT, @(x) isnat(x) || isdatetime(x))
            addParameter(ip, 'index0', this.index0, @isnumeric)
            addParameter(ip, 'indexF', this.indexF, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if isdatetime(ipr.datetimeForDecayCorrection) && ...
                    ~isnat(ipr.datetimeForDecayCorrection)
                this.datetimeForDecayCorrection = ipr.datetimeForDecayCorrection;
            end  
            if ipr.decayCorrected && ~this.decayCorrected
                this = this.decayCorrect();
            end
            
            [a,m] = this.activity(varargin{:});            
            assert(all(size(a) == size(this.visibleVolume)))
            a = a./this.visibleVolume;
        end
        function [c,m] = countRate(this, varargin)
            %% cps
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @return count-rate (cps), mass (g).
            
            ip = inputParser;
            addParameter(ip, 'decayCorrected', false, @islogical)
            addParameter(ip, 'datetimeForDecayCorrection', NaT, @(x) isnat(x) || isdatetime(x))
            addParameter(ip, 'index0', this.index0, @isnumeric)
            addParameter(ip, 'indexF', this.indexF, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if isdatetime(ipr.datetimeForDecayCorrection) && ...
                    ~isnat(ipr.datetimeForDecayCorrection)
                this.datetimeForDecayCorrection = ipr.datetimeForDecayCorrection;
            end  
            if ipr.decayCorrected && ~this.decayCorrected
                this = this.decayCorrect();
            end
            
            c = this.radMeasurements.countsFdg.W_01_Kcpm(this.countsFdgSelection);
            c = c*1e3/60;
            m = this.radMeasurements.countsFdg.MASSSAMPLE_G(this.countsFdgSelection);
        end
        function this = decayCorrect(this)
            if ~this.decayCorrected                
                vec = asrow(this.radMeasurements.countsFdg.Ge_68_Kdpm(this.countsFdgSelection));
                vec = vec .* asrow(2.^( (this.times - this.timeForDecayCorrection)/this.halflife));
                this.radMeasurements.countsFdg.Ge_68_Kdpm(this.countsFdgSelection) = ascol(vec);
                
                vec1 = asrow(this.radMeasurements.countsFdg.W_01_Kcpm(this.countsFdgSelection));
                vec1 = vec1 .* asrow(2.^( (this.times - this.timeForDecayCorrection)/this.halflife));
                this.radMeasurements.countsFdg.W_01_Kcpm(this.countsFdgSelection) = ascol(vec1);
                
                this.decayCorrected_ = true;
            end
        end
        function this = decayUncorrect(this)
            if this.decayCorrected
                vec = this.radMeasurements.countsFdg.Ge_68_Kdpm(this.countsFdgSelection);
                vec = vec .* asrow(2.^(-(this.times - this.timeForDecayCorrection)/this.halflife));
                this.radMeasurements.countsFdg.Ge_68_Kdpm(this.countsFdgSelection) = vec;
                
                vec1 = this.radMeasurements.countsFdg.W_01_Kcpm(this.countsFdgSelection);
                vec1 = vec1 .* asrow(2.^(-(this.times - this.timeForDecayCorrection)/this.halflife));
                this.radMeasurements.countsFdg.W_01_Kcpm(this.countsFdgSelection) = vec1;
                
                this.decayCorrected_ = false;
            end
        end
        function this = shiftWorldlines(this, Dt)
            %% shifts worldline of internal data self-consistently
            %  @param Dt is numeric.
            
            assert(isnumeric(Dt))
            Dt = asrow(Dt);
            
            c = asrow(this.radMeasurements.countsFdg.Ge_68_Kdpm);
            this.radMeasurements.countsFdg.Ge_68_Kdpm = ascol(c .* 2.^(-Dt/this.halflife));
            c1 = asrow(this.radMeasurements.countsFdg.W_01_Kcpm);
            this.radMeasurements.countsFdg.W_01_Kcpm = ascol(c1 .* 2.^(-Dt/this.halflife));
            
            this.datetimeMeasured = this.datetimeMeasured + seconds(Dt);
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        radMeasurements_
    end

	methods (Access = protected)		  
 		function this = CapracData(varargin)
 			%% CAPRACDATA

 			this = this@mlpet.AbstractTracerData(varargin{:});
            this.decayCorrected_ = false;
            this.radMeasurements_ = mlpet.CCIRRadMeasurements.createFromDate(this.datetimeMeasured);
            drawTimes = this.radMeasurements_.countsFdg.TIMEDRAWN_Hh_mm_ss(this.countsFdgSelection);
            this.datetimeMeasured = drawTimes(1) - this.clocksTimeOffsetWrtNTS;
            this.times = seconds(asrow(drawTimes - drawTimes(1)));
        end
        
        function sec = clocksTimeOffsetWrtNTS(this)
            try
                sec = seconds(this.radMeasurements.clocks.TimeOffsetWrtNTS____s('hand timers'));
            catch ME
                handwarning(ME)
                sec = seconds(this.radMeasurements.clocks.TIMEOFFSETWRTNTS____S('hand timers'));
            end
        end 
        function tf = countsFdgSelection(this)
            rm = this.radMeasurements;
            tf = logical(cell2mat(strfind(rm.countsFdg.TRACER, this.radionuclides_.isotope))) & ...
                isnice(rm.countsFdg.TIMEDRAWN_Hh_mm_ss) & ...
                isnice(rm.countsFdg.TIMECOUNTED_Hh_mm_ss) & ...
                isnice(rm.countsFdg.Ge_68_Kdpm) & ...
                isnice(rm.countsFdg.MASSSAMPLE_G);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

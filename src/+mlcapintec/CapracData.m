classdef CapracData < handle & mlpet.AbstractTracerData
	%% CAPRACDATA  

	%  $Revision$
 	%  was created 07-Mar-2020 13:47:02 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent)
        COMMENTS
        countsTableSelection
        Ge_68_Kdpm
        isWholeBlood
        MASSSAMPLE_G
 		radMeasurements
        TIMECOUNTED_Hh_mm_ss
        TIMEDRAWN_Hh_mm_ss
        TRACER
        visibleVolume % vector for syringe containing whole blood        
        W_01_Kcpm
 	end
    
    methods (Static)
        function this = createFromSession(sesd, varargin)
            assert(isa(sesd, 'mlpipeline.ISessionData') || ...
                isa(sesd, 'mlpipeline.ImagingMediator'))
            this = mlcapintec.CapracData( ...
                'isotope', sesd.isotope, ...
                'tracer', sesd.tracer, ...
                'datetimeMeasured', sesd.datetime, ...
                varargin{:});
        end
    end
    
    methods
        
        %% GET        
        
        function g = get.COMMENTS(this)
            g = this.radMeasurements.(this.countsTableName_).COMMENTS;
        end
        function g = get.countsTableSelection(this)
            try
                if ~isempty(this.countsTableSelection_)
                    g = this.countsTableSelection_;
                    return
                end

                g = contains(this.TRACER, this.radionuclides_.isotope) & ...
                    isnice(this.TIMEDRAWN_Hh_mm_ss) & ...
                    isnice(this.TIMECOUNTED_Hh_mm_ss) & ...
                    isnice(this.Ge_68_Kdpm) & ...
                    isnice(this.MASSSAMPLE_G);
                this.countsTableSelection_ = g;

                if contains(this.TRACER, 'fdg', IgnoreCase=true)
                    g = g(this.isWholeBlood);
                    this.countsTableSelection_ = g;
                end
            catch ME
                handexcept(ME)
            end
        end
        function g = get.Ge_68_Kdpm(this)
            g = this.radMeasurements.(this.countsTableName_).Ge_68_Kdpm;
        end
        function     set.Ge_68_Kdpm(this, s)
            assert(all(isnumeric(s)))
            this.radMeasurements.(this.countsTableName_).Ge_68_Kdpm = s;
        end
        function g = get.isWholeBlood(this)
            g = ~contains(this.COMMENTS(this.countsTableSelection), 'plasma', IgnoreCase=true);
        end
        function g = get.MASSSAMPLE_G(this)
            try
                g = this.radMeasurements.(this.countsTableName_).MASSSAMPLE_G;
            catch ME
                handwarning(ME)
                g = this.radMeasurements.(this.countsTableName_).MassSample_G;
            end
        end
        function     set.MASSSAMPLE_G(this, s)
            assert(all(isnumeric(s)))
            this.radMeasurements.(this.countsTableName_).MASSSAMPLE_G = s;
        end
        function g = get.radMeasurements(this)
            g = this.radMeasurements_;
        end
        function g = get.TIMECOUNTED_Hh_mm_ss(this)
            g = this.radMeasurements.(this.countsTableName_).TIMECOUNTED_Hh_mm_ss;
        end
        function g = get.TIMEDRAWN_Hh_mm_ss(this)
            g = this.radMeasurements.(this.countsTableName_).TIMEDRAWN_Hh_mm_ss;
        end
        function g = get.TRACER(this)
            g = this.radMeasurements.(this.countsTableName_).TRACER;
        end
        function g = get.visibleVolume(this)
            mass = this.MASSSAMPLE_G(this.countsTableSelection);
            g = mass/mlcapintec.CapracCalibration.BLOOD_DENSITY;
            g = asrow(g);
        end        
        function g = get.W_01_Kcpm(this)
            g = this.radMeasurements.(this.countsTableName_).W_01_Kcpm;
        end
        function     set.W_01_Kcpm(this, s)
            assert(all(isnumeric(s)))
            this.radMeasurements.(this.countsTableName_).W_01_Kcpm = s;
        end   
        
        %% 
        
        function a = activity(this, varargin)
            %% FDG Bq for whole blood in drawn syringes, without Caprac calibrations.
            %  See also mlcapintec.CapracDevice for implementation of calibrations.
            %  @return activity (Bq).
            
            a = this.Ge_68_Kdpm(this.countsTableSelection)*1e3/60;
            a = asrow(a);
            a = this.shiftCountTimeToDrawTime(a);
        end
        function [a,m] = activity_kdpm(this, varargin)
            %% FDG kdpm for whole blood in measured syringes, without Caprac calibrations.
            %  See also mlcapintec.CapracDevice for implementation of calibrations.
            %  @return activity (kdpm), mass (g).
            
            a = this.Ge_68_Kdpm(this.countsTableSelection);
            a = asrow(a);
            m = this.MASSSAMPLE_G(this.countsTableSelection);     
            m = asrow(m);
            assert(all(size(a) == size(m)))
        end
        function a = activityDensity(this, varargin)
            %% FDG Bq/mL for whole blood in drawn syringes, without Caprac calibrations.
            %  See also mlcapintec.CapracDevice for implementation of calibrations.            
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param index0.
            %  @param indexF.
            %  @return activity density (Bq/mL).
            
            ip = inputParser;
            ip.KeepUnmatched = true;
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
            
            a = this.Ge_68_Kdpm(this.countsTableSelection)*1e3/60;
            a = asrow(a);          
            assert(all(size(a) == size(this.visibleVolume)))
            a = a ./ this.visibleVolume;
            a = this.shiftCountTimeToDrawTime(a);
        end
        function c = countRate(this, varargin)
            %% FDG cps for whole blood in drawn syringes, without Caprac calibrations.
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param index0.
            %  @param indexF.
            %  @return count-rate (cps).
            
            ip = inputParser;
            ip.KeepUnmatched = true;
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
            
            c = this.W_01_Kcpm(this.countsTableSelection);
            c = c*1e3/60;
            c = asrow(c);
            c = this.shiftCountTimeToDrawTime(c);
        end
        function this = decayCorrect(this)
            if ~this.decayCorrected                
                vec = asrow(this.Ge_68_Kdpm(this.countsTableSelection));
                vec = vec .* asrow(2.^( (this.times - this.timeForDecayCorrection)/this.halflife));
                this.Ge_68_Kdpm(this.countsTableSelection) = ascol(vec);
                
                vec1 = asrow(this.W_01_Kcpm(this.countsTableSelection));
                vec1 = vec1 .* asrow(2.^( (this.times - this.timeForDecayCorrection)/this.halflife));
                this.W_01_Kcpm(this.countsTableSelection) = ascol(vec1);
                
                this.decayCorrected_ = true;
            end
        end
        function this = decayUncorrect(this)
            if this.decayCorrected
                vec = this.Ge_68_Kdpm(this.countsTableSelection);
                vec = vec .* asrow(2.^(-(this.times - this.timeForDecayCorrection)/this.halflife));
                this.Ge_68_Kdpm(this.countsTableSelection) = vec;
                
                vec1 = this.W_01_Kcpm(this.countsTableSelection);
                vec1 = vec1 .* asrow(2.^(-(this.times - this.timeForDecayCorrection)/this.halflife));
                this.W_01_Kcpm(this.countsTableSelection) = vec1;
                
                this.decayCorrected_ = false;
            end
        end
        function this = shiftWorldlines(this, Dt, varargin)
            %% shifts worldline of internal data self-consistently
            %  @param required Dt is scalar:  timeShift > 0 shifts into future; timeShift < 0 shifts into past.
            %  @param shiftDatetimeMeasured is logical.
            
            ip = inputParser;
            addRequired(ip, 'Dt', @isscalar)
            addParameter(ip, 'shiftDatetimeMeasured', true, @islogical)
            parse(ip, Dt, varargin{:})
            assert(isscalar(this.halflife))
            assert(isrow(this.datetimeMeasured))
            
            Dt = asrow(Dt);            
            c = asrow(this.Ge_68_Kdpm);
            this.Ge_68_Kdpm = ascol(c .* 2.^(-Dt/this.halflife));
            c1 = asrow(this.W_01_Kcpm);
            this.W_01_Kcpm = ascol(c1 .* 2.^(-Dt/this.halflife));
            
            if ip.Results.shiftDatetimeMeasured
                this.datetimeMeasured = this.datetimeMeasured + seconds(Dt);
            end
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        countsTableName_
        countsTableSelection_
        radMeasurements_
    end

	methods (Access = protected)		  
 		function this = CapracData(varargin)
 			%% CAPRACDATA

 			this = this@mlpet.AbstractTracerData(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'radMeasurements', [], @(x) isa(x, 'mlpet.RadMeasurements') || isempty(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.decayCorrected_ = false;
            if ~isempty(ipr.radMeasurements)
                this.radMeasurements_ = ipr.radMeasurements;
            else
                this.radMeasurements_ = mlpet.CCIRRadMeasurements.createFromDate(this.datetimeMeasured);
            end
            switch lower(this.tracer_)
                case {'fdg' 'ho' 'oh'}
                    this.countsTableName_ = 'countsFdg';
                case {'co' 'oc' 'oo'}
                    this.countsTableName_ = 'countsOcOo';
                otherwise
                    error('mlcapintec:ValueError', ...
                        'CapracData.countsTablename_->%s is not yet supported', this.countsTableName_)
            end
            if ~any(this.countsTableSelection)
                warning('mlcapintec:ValueWarning', ...
                    'CapracData.ctor():  %s is incomplete', this.countsTableName_)
                return
            end
            drawTimes = this.TIMEDRAWN_Hh_mm_ss(this.countsTableSelection);
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
        function a = shiftCountTimeToDrawTime(this, a)
            a = asrow(a);
            Dt = asrow(seconds(this.TIMECOUNTED_Hh_mm_ss(this.countsTableSelection) - ...
                               this.TIMEDRAWN_Hh_mm_ss(this.countsTableSelection)));
            a = a .* 2.^(Dt/this.halflife);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

classdef CapracDevice < handle & mlpet.AbstractDevice
	%% CAPRACDEVICE  
    %  1/22/2016
    %  4/8/2016
    %  8/10/2018
    %  8/13/2018
    %  9/12/2018 
    %  10/5/2018 invEff = 1.031

	%  $Revision$
 	%  was created 18-Oct-2018 14:00:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
        CS_RESCALING = 1.204 % empirical estimate for comparisons with [68Ge]
 		MAX_NORMAL_BACKGROUND = 300 % cpm
    end
    
    properties (Dependent)
        background
        calibrationAvailable
        convertToPlasma
        hct
    end
    
    methods (Static)
        function this = createFromSession(varargin)
            data = mlcapintec.CapracData.createFromSession(varargin{:});
            rm   = mlpet.CCIRRadMeasurements.createFromSession(varargin{:});
            hct  = rm.fromPamStone{'Hct',1};
            hct  = str2double(hct{1});
            this = mlcapintec.CapracDevice( ...
                'calibration', mlcapintec.CapracCalibration.createFromSession(varargin{:}), ...
                'data', data, ...
                'hct', hct);
        end
        function ie = invEfficiencyf(varargin)
            %% INVEFFICIENCYF     
            %  @param ge68 is numeric.
            %  @param mass is numeric.
            %  @param solvent is in {'water' 'plasma' 'blood'}.  Default := 'blood'.
            
            import mlcapintec.CapracCalibration
            import mlcapintec.RefSourceCalibration
            
            ip = inputParser;
            addParameter(ip, 'ge68', NaN, @isnumeric)
            addParameter(ip, 'mass', NaN, @isnumeric)
            addParameter(ip, 'solvent', 'blood', @ischar)
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            ie = CapracCalibration.invEfficiencyf('ge68', ipr.ge68, 'mass', ipr.mass, 'solvent', ipr.solvent) .* ...
                 RefSourceCalibration.invEfficiencyf();            
        end
        function a = blood2plasma(a, hct, t)
            assert(isnumeric(a))
            assert(isscalar(hct))
            assert(isnumeric(t))            
            if (hct > 1)
                hct = hct/100;
            end
            lambda_t = mlcapintec.CapracDevice.rbcOverPlasma(t);
            a = a./(1 + hct*(lambda_t - 1));
        end        
        function rop = rbcOverPlasma(t)
            %% RBCOVERPLASMA is [FDG(RBC)]/[FDG(plasma)]
            
            t   = t/60;      % sec -> min
            a0  = 0.814104;  % FINAL STATS param  a0 mean  0.814192	 std 0.004405
            a1  = 0.000680;  % FINAL STATS param  a1 mean  0.001042	 std 0.000636
            a2  = 0.103307;  % FINAL STATS param  a2 mean  0.157897	 std 0.110695
            tau = 50.052431; % FINAL STATS param tau mean  116.239401	 std 51.979195
            rop = a0 + a1*t + a2*(1 - exp(-t/tau));
        end
    end

	methods 
        
        %% GET
        
        function g = get.background(this)
            g = this.background_;
        end
        function g = get.calibrationAvailable(this)
            g = this.calibration_.calibrationAvailable;
        end
        function g = get.convertToPlasma(this)
            g = this.convertToPlasma_;
        end
        function     set.convertToPlasma(this, s)
            assert(islogical(s))
            this.convertToPlasma_ = s;
        end
        function g = get.hct(this)
            g = this.hct_;
        end
        
        %%        
        
        function a = activity(this, varargin)
            %% FDG Bq for whole blood in drawn syringes, with plasma correction, without ref-source calibrations.
            %  See also mlcapintec.CapracDevice for implementation of calibrations.
            %  @param mass is numeric.
            %  @param ge68 is numeric.
            %  @param solvent is in {'water' 'plasma' 'blood'}.
            %  @return activity (Bq).
            
            import mlcapintec.CapracDevice.blood2plasma
            
            a     = this.data_.activity(varargin{:});
            [g,m] = this.data_.activity_kdpm(varargin{:});
            a     = a .* this.invEfficiencyf('ge68', g, 'mass', m, varargin{:});
            if this.convertToPlasma_
                a = blood2plasma(a, this.hct, this.data_.times);
            end
        end
        function a = activityDensity(this, varargin)
            %% FDG Bq/mL for whole blood in drawn syringes, with plasma correction, without ref-source calibrations.
            %  See also mlcapintec.CapracDevice for implementation of calibrations.   
            %  @param mass is numeric.
            %  @param ge68 is numeric.
            %  @param solvent is in {'water' 'plasma' 'blood'}.         
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param index0.
            %  @param indexF.
            %  @return activity density (Bq/mL).
            
            import mlcapintec.CapracDevice.blood2plasma
                        
            a     = this.data_.activityDensity(varargin{:});
            [g,m] = this.data_.activity_kdpm(varargin{:});
            a     = a .* this.invEfficiencyf('ge68', g, 'mass', m, varargin{:});
            if this.convertToPlasma_
                a = blood2plasma(a, this.hct, this.data_.times);
            end
        end
        function c = countRate(this, varargin)
            %% FDG cps in drawn syringes, without plasma correction, without ref-source calibrations.
            %  @param mass is numeric.
            %  @param ge68 is numeric.
            %  @param solvent is in {'water' 'plasma' 'blood'}.
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param index0.
            %  @param indexF.
            %  @return count-rate (cps).
            
            c     = this.data_.countRate(varargin{:});
            [g,m] = this.data_.activity_kdpm(varargin{:});
            c     = c .* this.invEfficiencyf('ge68', g, 'mass', m, varargin{:});
        end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)
 		function this = CapracDevice(varargin)
 			%% CAPRACDEVICE

            this = this@mlpet.AbstractDevice(varargin{:});  
            this = this.checkBackgroundMeasurements;
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'convertToPlasma', true, @islogical)
            addParameter(ip, 'hct', 45, @isscalar)
            parse(ip, varargin{:});
            this.convertToPlasma_ = ip.Results.convertToPlasma;
            this.hct_ = ip.Results.hct;
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        background_  
        convertToPlasma_
        hct_
    end
    
    methods (Access = private)
        function this = checkBackgroundMeasurements(this)
            %% CHECKBACKGROUNDMEASUREMENTS warns if measurements in this.radMeasurements are concerning.
            
            rm = this.radMeasurements;
            assert(isprop(rm, 'countsFdg'), 'mlcapintec:ValueError', 'CapracDevice.checkBackgroundMeasurements');
            assert(isprop(rm, 'countsOcOo'), 'mlcapintec:ValueError', 'CapracDevice.checkBackgroundMeasurements');
            assert(isprop(rm, 'wellCounter'), 'mlcapintec:ValueError', 'CapracDevice.checkBackgroundMeasurements');
            
            time = [rm.countsFdg.Time_Hh_mm_ss; ...
                    rm.countsOcOo.Time_Hh_mm_ss; ...
                    rm.wellCounter.Time_Hh_mm_ss];
            counts = [rm.countsFdg.COUNTS_Cpm; ...
                      rm.countsOcOo.COUNTS_Cpm; ...
                      rm.wellCounter.COUNTS_Cpm];
            countsSE = [rm.countsFdg.countsS_E__Cpm; ...
                        rm.countsOcOo.countsS_E__Cpm; ...
                        rm.wellCounter.countsS_E__Cpm];
            entered = [rm.countsFdg.ENTERED; ...
                       rm.countsOcOo.ENTERED; ...
                       rm.wellCounter.ENTERED];
            entered  = entered( isnice(time) & isnice(counts));
            countsSE = countsSE(isnice(time) & isnice(counts));
            counts   = counts(  isnice(time) & isnice(counts));
            time     = time(    isnice(time));
            bg       = table(time, counts, countsSE, entered);
            
            if (any(counts > this.MAX_NORMAL_BACKGROUND))
                wid = 'mlcapintec:ValueWarning';
                wmsg = sprintf('CapracDevice.checkBackgroundMeasurements.counts->%g', this.MAX_NORMAL_BACKGROUND);
                warning(wid, wmsg); %#ok<SPWRN>
                plot(bg.time, bg.counts);
                ylabel('cpm');
                xlabel('datetime');
                title(sprintf('%s\n%s', wid, wmsg));
            end
            if (any(countsSE > this.MAX_NORMAL_BACKGROUND/10))
                wid = 'mlcapintec:ValueWarning';
                wmsg = sprintf('CapracDevice.checkBackgroundMeasurements.countsSE->%g', this.MAX_NORMAL_BACKGROUND/10);
                warning(wid, wmsg); %#ok<SPWRN>
                plot(bg.time, bg.countsSE);
                ylabel('cpm');
                xlabel('datetime');
                title(sprintf('%s\n%s', wid, wmsg));
            end
            this.background_ = bg;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

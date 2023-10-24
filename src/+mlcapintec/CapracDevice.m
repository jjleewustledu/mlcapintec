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
        deconvCatheter = false
 		MAX_NORMAL_BACKGROUND = 300 % cpm
    end
    
    properties (Dependent)
        background
        calibrationAvailable
        countsTableSelection
        Dt
        hct
        isWholeBlood
    end
    
    methods (Static)
        function this = createFromSession(varargin)
            data = mlcapintec.CapracData.createFromSession(varargin{:});
            rm   = data.radMeasurements;
            hct  = rm.laboratory{'Hct',1};
            %hct  = str2double(hct{1});
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
            ip.KeepUnmatched = true;
            addParameter(ip, 'ge68', NaN, @isnumeric)
            addParameter(ip, 'mass', NaN, @isnumeric)
            addParameter(ip, 'solvent', 'blood', @ischar)
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            ie = CapracCalibration.invEfficiencyf('ge68', ipr.ge68, 'mass', ipr.mass, 'solvent', ipr.solvent) .* ...
                 RefSourceCalibration.invEfficiencyf();            
        end
    end

	methods 
        
        %% GET/SET
        
        function g = get.background(this)
            g = this.background_;
        end
        function g = get.calibrationAvailable(this)
            g = this.calibration_.calibrationAvailable;
        end
        function g = get.countsTableSelection(this)
            g = this.data_.countsTableSelection;
        end
        function g = get.Dt(this)
            g = this.Dt_;
        end
        function     set.Dt(this, s)
            assert(isscalar(s))
            this.Dt_ = s;
        end
        function g = get.hct(this)
            g = this.hct_;
        end
        function g = get.isWholeBlood(this)
            g = this.data_.isWholeBlood;
        end
        
        %%        
        
        function a = activity(this, varargin)
            %% FDG Bq for whole blood in drawn syringes, with plasma correction, without ref-source calibrations.
            %  See also mlcapintec.CapracDevice for implementation of calibrations.
            %  @param mass is numeric.
            %  @param ge68 is numeric.
            %  @param solvent is in {'water' 'plasma' 'blood'}.
            %  @return activity (Bq).
            
            a = this.data_.activity(varargin{:});
            [g,m] = this.data_.activity_kdpm(varargin{:});
            a = a .* this.invEfficiencyf('ge68', g, 'mass', m, varargin{:});
            a = this.wb2plasma(a, this.hct, this.data_.times); % applies only to FDG
        end
        function a = activityDensity(this, varargin)
            %% FDG Bq/mL for whole blood in drawn syringes, with plasma correction, with ref-source calibrations.
            %  See also mlcapintec.CapracDevice for implementation of calibrations.   
            %  @param mass is numeric.
            %  @param ge68 is numeric.
            %  @param solvent is in {'water' 'plasma' 'blood'}.         
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param index0.
            %  @param indexF.
            %  @return activity density (Bq/mL).
            
            a = this.data_.activityDensity(varargin{:});
            [g,m] = this.data_.activity_kdpm(varargin{:});
            a = a .* this.invEfficiencyf('ge68', g, 'mass', m, varargin{:});
            a = this.wb2plasma(a, this.hct, this.data_.times); % applies only to FDG
        end
        function [a1,t1] = activityDensityInterp1(this, varargin)
            t = this.times;
            %t = t(this.isWholeBlood');
            a = this.activityDensity(varargin{:});
            %a = a(this.isWholeBlood');

            t1 = t(1):1:t(end);
            a1 = interp1(t, a, t1);            
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
            addParameter(ip, 'hct', 45, @isscalar)
            parse(ip, varargin{:});
            this.hct_ = ip.Results.hct;
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        background_  
        Dt_
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
            counts = [this.ensureMat(rm.countsFdg.COUNTS_Cpm); ...
                      this.ensureMat(rm.countsOcOo.COUNTS_Cpm); ...
                      this.ensureMat(rm.wellCounter.COUNTS_Cpm)];
            countsSE = [this.ensureMat(rm.countsFdg.countsS_E__Cpm); ...
                        this.ensureMat(rm.countsOcOo.countsS_E__Cpm); ...
                        this.ensureMat(rm.wellCounter.countsS_E__Cpm)];
            entered = [rm.countsFdg.ENTERED; ...
                       rm.countsOcOo.ENTERED; ...
                       rm.wellCounter.ENTERED];
            time_ = time;
            counts_ = counts;
            entered  = entered( isnice(time_) & isnice(counts_));
            countsSE = countsSE(isnice(time_) & isnice(counts_));
            counts   = counts(  isnice(time_) & isnice(counts_));
            time     = time(    isnice(time_) & isnice(counts_));
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
        function n = ensureMat(~, c)
            if isnumeric(c)
                n = c;
                return
            end
            c = cellfun(@str2double, c, 'UniformOutput', false);
            n = cell2mat(c);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

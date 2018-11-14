classdef CapracDevice < handle & mlpet.Instrument
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
        CS_RESCALING = 1.204
 		MAX_NORMAL_BACKGROUND = 300
    end
    
    properties (Dependent)
        background
        hasReferenceSourceMeasurements
        referenceSources
    end
    
    methods (Static)
        function checkRangeInvEfficiency(ie)
            %  @param required ie is numeric.
            %  @throws mlcapintec:ValueError.
            
            assert(all(0.95 < ie) && all(ie < 1.05), ...
                'mlcapintec:ValueError', ...
                'CapracDevice.checkRangeInvEfficiency.ie->%s', mat2str(ie));
        end
        function [cal,h1,h2] = screenInvEfficiencies(varargin)
            %  @param filepath is dir; default := getenv('CCIR_RAD_MEASUREMENTS_DIR').
            %  @param refSource is mlpet.ReferenceSource.
            %  @return cal is CapracCalibration; h1, h2 are figure handles.
            %  @return plot.
            
            [cal,h1,h2] = mlcapintec.RefSourceCalibration.screenInvEfficiencies(varargin{:});
        end
        function [cal,h1,h2] = screenInvEfficiency(varargin)
            %  @param filepath is dir; default := getenv('CCIR_RAD_MEASUREMENTS_DIR').
            %  @param filename is char.
            %  @param refSource is mlpet.ReferenceSource.
            %  @return cal is CapracCalibration; h1, h2 are figure handles.
            %  @return plot.

            [cal,h1,h2] = mlcapintec.RefSourceCalibration.screenInvEfficiency(varargin{:});
        end
    end

	methods 
        
        %% GET
        
        function g = get.background(this)
            g = this.background_;
        end
        function g = get.hasReferenceSourceMeasurements(this)
            g = ~isempty(this.referenceSources) && ~isempty(this.radMeasurements.wellCounterRefSrc);
        end
        function g = get.referenceSources(this)
            g = this.referenceSources_;
        end
        
        %%
        
        function this = calibrateDevice(this)
            %% CALIBRATEDEVICE prepares invEfficiency and calibrateMeasurements for this instrument using calibration data.
            
            this.calibrations_.withRefSource = this.estimateInvEfficiencyFromReferenceSources;
            this.calibrations_.withSensitivity = [];
            this.calibrations_.withAperture = [];
        end
        function m    = calibrateMeasurement(this, varargin)
            m = this.calibrateWithRefSource( ...
                    this.calibrateWithSensitivity( ...
                        this.calibrateWithAperture(ip.Results.measurement)));
        end
        function m    = calibrateWithAperture(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'measurement', @isnumeric);
            parse(ip);
        end
        function m    = calibrateWithRefSource(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'measurement', @isnumeric);
            parse(ip);
        end
        function m    = calibrateWithSensitivity(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'measurement', @isnumeric);
            parse(ip);
        end
        function ie   = invEfficiency(this, varargin)
            %% INVEFFICIENCY is the linear estimate of the mapping from raw measurements to calibrated measurements.
            %  @throws mlpet.ValueError if the gradient of the estimate exceeds Instrument.ALPHA.
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'measurement', @isnumeric);
            parse(ip);
            
            ie = this.calibrateMeasurement(varargin{:}) ./ ip.Results.measurement;            
            this.checkRangeInvEfficiency(ie); 
        end
        
 		function this = CapracDevice(varargin)
 			%% CAPRACDEVICE
            %  @param referenceSources is mlpet.ReferenceSource, typically a composite.
 			%  @param radMeasurements is mlpet.RadMeasurements.

            this = this@mlpet.Instrument(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'referenceSources', [], @(x) isa(x, 'mlpet.ReferenceSource') || isempty(x));
            parse(ip, varargin{:});
            this.referenceSources_ = ip.Results.referenceSources;
            this = this.checkBackgroundMeasurements;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        background_  
        invEfficieny_
        referenceSources_
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
            entered  = entered( ~isempty(time) && ~isempty(counts));
            countsSE = countsSE(~isempty(time) && ~isempty(counts));
            counts   = counts(  ~isempty(time) && ~isempty(counts));
            time     = time(    ~isempty(time) && ~isempty(counts));
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
        function ie   = estimateInvEfficiencyFromReferenceSources(this)
            if (this.onlyCsAvailable)
                ie = this.estimateInvEfficiencyFromReferenceSource(this, '[137Cs]');
                return
            end
            ie = [this.estimateInvEfficiencyFromReferenceSource('[22Na]') ...
                  this.estimateInvEfficiencyFromReferenceSource('[68Ge]') ...
                  this.estimateInvEfficiencyFromReferenceSource('[137Cs]')]; % for logging only
            ie = mean(ie(~isempty(ie)));
        end
        function ie   = estimateInvEfficiencyFromReferenceSource(this, isotope)
            rm = this.radMeasurements;
            assert(any(contains(rm.REFERENCE_SOURCES, isotope)));
            switch (isotope)
                case '[137Cs]'
                    ie = this.predictedReferenceSourceActivity(isotope, 'kdpm')./ ...
                        (this.CS_RESCALING*rm.wellCounterRefSrc(isotope).CF_Kdpm');
                    
                case {'[22Na]' '[68Ge]'}
                    ie = this.predictedReferenceSourceActivity(isotope, 'kdpm')./ ...
                        rm.wellCounterRefSrc(isotope).Ge_68_Kdpm';
                otherwise
                    error('mlcapintec:ValueError', ...
                        'CapracDevice.estimateInvEfficiencyFromReferenceSource.isotope->%s is not supported', ...
                        isotope);
            end
            this.checkRangeInvEfficiency(ie);
            ie = mean(ie);
        end
        function tf   = onlyCsAvailable(this)
            rm = this.radMeasurements;
            tf = ~isempty(rm.wellCounterRefSrc('[137Cs]')) && ...
                  isempty(rm.wellCounterRefSrc('[22Na]')) && ...
                  isempty(rm.wellCounterRefSrc('[68Ge]'));
        end
        function a    = predictedReferenceSourceActivity(this, isotope, activityUnits)
            %  @param isotope is char.
            %  @param activityUnits of returned is char.
            %  @returns activity is numeric.
            
            rs = this.selectReferenceSource(isotope);
            wcrs = this.radMeasurements.wellCounterRefSrc(isotope);
            a = [];
            for iwcrs = 1:height(wcrs)
                a = [a rs.predictedActivity(wcrs{iwcrs,'TIMECOUNTED_Hh_mm_ss'}, activityUnits)]; %#ok<AGROW>
            end
        end
        function rs   = selectReferenceSource(this, isotope)
            %  @param isotope is char.
            %  @throws mlcapintec:ValueError is ref source is not unique to isotope.
            
            rs = [];
            for irs = 1:length(this.referenceSources)
                if (strcmp(this.referenceSources(irs).isotope, isotope))
                    rs = [rs this.referenceSources(irs)]; %#ok<AGROW>
                end
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


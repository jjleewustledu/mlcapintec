classdef CapracDevice < handle & mlpet.Instrument
	%% CAPRACDEVICE  

	%  $Revision$
 	%  was created 18-Oct-2018 14:00:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
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
            %% CALIBRATEDEVICE sets invEfficiency for this instrument by comparing its calibration data 
            %  against reference data.
            
            if (this.hasReferenceSourceMeasurements)
                this.invEfficieny_ = this.estimateInvEfficiencyFromReferenceSources;
                return
            end            
            this.invEfficiency_ = 1;
        end
        function d = makeMeasurements(this)
            error('mlpet:NotImplementedError');
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
            this = this.checkBackground;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        background_  
        referenceSources_
    end
    
    methods (Access = private)
        function this = checkBackground(this)
            %% CHECKBACKGROUND warns if measurements in this.radMeasurements are concerning.
            
            rm = this.radMeasurements;
            assert(isprop(rm, 'countsFdg'), 'mlcapintec:ValueError', 'CapracDevice.checkBackground');
            assert(isprop(rm, 'countsOcOo'), 'mlcapintec:ValueError', 'CapracDevice.checkBackground');
            assert(isprop(rm, 'wellCounter'), 'mlcapintec:ValueError', 'CapracDevice.checkBackground');
            
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
                wmsg = sprintf('CapracDevice.checkBackground.counts->%g', this.MAX_NORMAL_BACKGROUND);
                warning(wid, wmsg); %#ok<SPWRN>
                plot(bg.time, bg.counts);
                ylabel('cpm');
                xlabel('datetime');
                title(sprintf('%s\n%s', wid, wmsg));
            end
            if (any(countsSE > this.MAX_NORMAL_BACKGROUND/10))
                wid = 'mlcapintec:ValueWarning';
                wmsg = sprintf('CapracDevice.checkBackground.countsSE->%g', this.MAX_NORMAL_BACKGROUND/10);
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
            ie = mean( ...
                this.estimateInvEfficiencyFromReferenceSource(this, '[22Na]'), ...
                this.estimateInvEfficiencyFromReferenceSource(this, '[68Ge]'));
                this.estimateInvEfficiencyFromReferenceSource(this, '[137Cs]'); % for logging only
        end
        function ie   = estimateInvEfficiencyFromReferenceSource(this, isotope)
            rm = this.radMeasurements;
            assert(contains(rm.REFERENCE_SOURCES, isotope));
            switch (isotope)
                case '[137Cs]'
                    ie = this.predictedReferenceSourceActivity(isotope, 'kdpm')./ ...
                        rm.wellCounterRefSrc(isotope).CF_Kdpm;
                    
                case {'[22Na]' '[68Ge]'}
                    ie = this.predictedReferenceSourceActivity(isotope, 'kdpm')./ ...
                        rm.wellCounterRefSrc(isotope).Ge_68_Kdpm;
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
            a = rs.predictedActivity(rs.activity, rs.activityUnits, activityUnits);
        end
        function rs   = selectReferenceSource(this, isotope)
            %  @param isotope is char.
            %  @throws mlcapintec:ValueError is ref source is not unique to isotope.
            
            rs = [];
            for irs = 1:length(this.referenceSources)
                if (strcmp(this.referenceSource(irs).isotope, isotope))
                    rs = [rs this.referenceSource(irs)]; %#ok<AGROW>
                end
            end
            assert(1 == length(rs), ...
                'mlcapintec:ValueError', ...
                'CapracDevice.selectReferenceSource found %i ref sources for %i', length(rs), isotope);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


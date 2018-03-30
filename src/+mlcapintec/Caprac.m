classdef Caprac < mlpet.AbstractAifData
	%% CAPRAC  

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee. 	

    properties (Constant)
        KDPM_TO_BQ  = 1000/60
        KCPM_TO_CPS = 1000/60
    end
    
	properties (Dependent) 
        invEfficiency % outer-most efficiency for s.a. determined by cross-calibration
    end
    
    methods      
        
        %% GET/SET
        
        function g    = get.invEfficiency(this)
            g = this.invEfficiency_;
        end
        function this = set.invEfficiency(this, s)
            this.invEfficiency_ = s;
            this = this.updateActivities;
        end
        
        %%
        
        function dt_  = datetime(this, varargin)
            %% DATETIME excludes inappropriate data using this.isValidTableRow.
            
            dt_ = this.measurementsTable2DatetimesDrawn;      
        end  
        function        plot(this, varargin)
            this.plotSpecificActivity(varargin{:});
        end
        function        plotCounts(this, varargin)  
            figure;
            plot(this.datetime, this.counts, varargin{:});
            xlabel(sprintf('datetime from %s', this.datetime0));
            ylabel('counts');
            title(sprintf('Caprac.plotCounts, cps:  time0->%g, timeF->%g', this.time0, this.timeF), ...
                'Interpreter', 'none');
        end
        function        plotSpecificActivity(this, varargin)
            figure;
            plot(this.datetime, this.specificActivity, varargin{:});
            xlabel(sprintf('datetime from %s', this.datetime0));
            ylabel('specificActivity');
            title(sprintf( ...
                'Caprac.plotSpecificActivity, Bq/mL  time0->%g, timeF->%g, Eff^{-1}->%g', ...
                this.time0, this.timeF, this.invEfficiency), ...
                'Interpreter', 'none');
        end
        function        save(~)
            error('mlpet:notImplemented', 'Caprac.save');
        end
        function v    = visibleVolume(this, varargin)
            %  @param measurements @istable.
            %  @return v in mL is row vector.
            
            ip = inputParser;
            addOptional(ip, measurements, this.fdg, @istable);
            parse(ip, varargin{:});
            
            m = ip.Results.measurements.MASSSAMPLE_G; % g
            v = m/mlpet.Blood.BLOODDEN; % mL
            v = ensureRowVector(v); % empirically measured on Caprac
        end
        
 		function this = Caprac(varargin)
 			%% CAPRAC

            this = this@mlpet.AbstractAifData(varargin{:});    
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'manualData', [],   @(x) isa(x, 'mldata.IManualMeasurements'));
            addParameter(ip, 'invEfficiency', 1, @isnumeric);
            addParameter(ip, 'aifTimeShift', 0,  @isnumeric);
            parse(ip, varargin{:});            
            this.manualData_ = ip.Results.manualData;
            this.timingData_ = mldata.TimingData( ...
                'times', this.manualData_.timingData.times, ...
                'dt', this.manualData_.timingData.dt); 
            this.invEfficiency_ = ip.Results.invEfficiency;
            this = this.shiftTimes(ip.Results.aifTimeShift); % @deprecated  
            
            this = this.updateActivities;
            this.isDecayCorrected_ = false;
            this.isPlasma = false;
        end        
    end
    
    %% PROTECTED    
    
    properties (Access = protected)
        invEfficiency_
        timingData_
    end

    methods (Access = protected)
        function tf   = isValidTableRow(this, varargin)
            ip = inputParser;
            addOptional( ip, 'aTable', this.manualData_.fdg, @istable);
            addParameter(ip, 'tracerName', '', @ischar);
            parse(ip, varargin{:});
            
            try
                tf = ~isnat(ip.Results.aTable.TIMEDRAWN_Hh_mm_ss) & ...
                     ~isnan(ip.Results.aTable.Ge_68_Kdpm) & ...
                            ip.Results.aTable.MASSSAMPLE_G > 0;
            catch ME
                try
                tf = ~isnat(ip.Results.aTable.TIMEDRAWN_Hh_mm_ss) & ...
                     ~isnan(ip.Results.aTable.ge_68_Kdpm) & ...
                            ip.Results.aTable.MASSSAMPLE_G > 0;
                catch ME
                    try
                        tf = ~isnat(ip.Results.aTable.TIMEDRAWN_Hh_mm_ss) & ...
                             ~isnan(ip.Results.aTable.Ge_68_Kdpm) & ...
                                    ip.Results.aTable.MassSample_G > 0;
                    catch ME
                        try
                            tf = ~isnat(ip.Results.aTable.TIMEDRAWN_Hh_mm_ss) & ...
                                 ~isnan(ip.Results.aTable.ge_68_Kdpm) & ...
                                        ip.Results.aTable.MassSample_G > 0;
                        catch ME
                        end
                    end
                end
            end
            if (~isempty(ip.Results.tracerName))
                tf = tf & strcmp(ip.Results.aTable, ip.Results.tracerName);
            end
        end
        function t    = measurementsTable2DatetimesDrawn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'measurements', this.manualData_.fdg, @istable);
            parse(ip, varargin{:});
            
            t = ip.Results.measurements.TIMEDRAWN_Hh_mm_ss;
            t = t(this.isValidTableRow(ip.Results.measurements));
            t = ensureRowVector(t);
        end
        function t    = measurementsTable2DatetimesCounted(this, varargin)
            ip = inputParser;
            addOptional(ip, 'measurements', this.manualData_.fdg, @istable);
            parse(ip, varargin{:});
            
            t = ensureRowVector(ip.Results.measurements.TIMECOUNTED_Hh_mm_ss);
            t = t(this.isValidTableRow(ip.Results.measurements));
        end
        function c    = measurementsTable2counts(this, varargin)
            %  @return row-vector of counts (counts/s).
            
            ip = inputParser;
            addOptional(ip, 'measurements', this.manualData_.fdg, @istable);
            parse(ip, varargin{:});            
            
            isvalid = this.isValidTableRow(ip.Results.measurements);
            try
                m  = ip.Results.measurements.MASSSAMPLE_G; % g
            catch                
                m  = ip.Results.measurements.MassSample_G; % g
            end
            m  = m(isvalid);
            g  = ip.Results.measurements.W_01_Kcpm; % kcpm
            g  = g(isvalid);
            c  = this.manualData_.capracInvEfficiency(g, m); % kcpm, efficiency-corrected
            c  = c * mlpet.Blood.BLOODDEN * this.KCPM_TO_CPS; % cps
            c  = ensureRowVector(c);
        end
        function sa   = measurementsTable2specificActivity(this, varargin)
            %  @param  measurements table from mldata.IManualMeasurements, @istable.
            %  @return row-vector of specificActivity (Bq/mL).
            
            ip = inputParser;
            addOptional(ip, 'measurements', this.manualData_.fdg, @istable);
            parse(ip, varargin{:});            
            
                isvalid = this.isValidTableRow(ip.Results.measurements);
                try
                    m  = ip.Results.measurements.MASSSAMPLE_G; % g
                catch ME
                    %dispwarning(ME);
                    m  = ip.Results.measurements.MassSample_G; % g
                end
                m  = m(isvalid);
                try
                    g  = ip.Results.measurements.Ge_68_Kdpm; % kdpm
                catch ME
                    %dispwarning(ME);
                    g  = ip.Results.measurements.ge_68_Kdpm; % kdpm                    
                end
                g  = g(isvalid);
                sa = this.manualData_.capracInvEfficiency(g./m, m); % kdpm/g, efficiency-corrected
                sa = sa * mlpet.Blood.BLOODDEN * this.KDPM_TO_BQ; % Bq/mL
                sa = ensureRowVector(sa);
        end
        function this = updateActivities(this)
            this = this.updateTimingData;
            this.decayCorrection_ = mlpet.DecayCorrection.factoryFor(this);
            this.counts_ = this.measurementsTable2counts;       
            this.specificActivity_ = this.invEfficiency_ * this.measurementsTable2specificActivity;  
        end
        function this = updateTimingData(this)
            dt_ = this.datetime;
            this.timingData_.times = seconds(dt_ - dt_(1));
            this.timingData_.datetime0 = dt_(1);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


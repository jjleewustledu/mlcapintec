classdef Caprac < mlpet.AbstractAifData
	%% CAPRAC  

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

	properties 
        dryWeight % as col vector
        wetWeight % as col vector
        drawn     % datetime
        counted   % datetime        
        drawnMin   % as col vector
        drawnSec   % as col vector
        countedMin % as col vector
        countedSec % as col vector
        nSyringes  % quantity of syringes used        
        
        isDecayCorrected = true
    end 
    
	properties (Dependent)
        clockDurationOffsets
        datetimeDrawn
        DACGe68      
        scannerData
        sessionData
        tableCaprac        
    end
    
    methods %% GET/SET
        function g = get.clockDurationOffsets(this)
            c = this.tableCaprac_.clocks{:,'TimeOffsetWrtNTS____s'};
            s = sign(c);
            c = this.datetime(abs(c));            
            c.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            d = this.datetime(0);
            d.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            g = s.*duration(c - d);
        end
        function g = get.datetimeDrawn(this)
            g = this.datetime;
        end
        function g = get.DACGe68(this)
            g = this.tableCaprac_.well.DECAY_APERTURECORRGE_68_Kdpm_G;
            g = g(this.validSamples_);
            g = g*this.invEfficiency;
        end
        function g = get.scannerData(this)
            g = this.scannerData_;
        end
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        function g = get.tableCaprac(this)
            g = this.tableCaprac_;
        end
    end

    methods (Static)
        function this = load(varargin)
            this = mlcapintec.Caprac(varargin{:});
        end
    end
      
	methods
        function dt   = datetime(this, varargin)
            for v = 1:length(varargin)
                if (ischar(varargin{v}))
                    try
                        varargin{v} = datetime(varargin{v}, 'InputFormat', 'HH:mm:ss', 'TimeZone', 'local');
                    catch ME
                        handwarning(ME);
                        varargin{v} = datetime(varargin{v}, 'InputFormat', 'HH:mm', 'TimeZone', 'local');
                    end
                end
                dt = datetime(varargin{v}, 'ConvertFrom', 'excel1904', 'TimeZone', 'local');
                dt.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
                dt = this.correctDateToReferenceDate(dt);
            end
        end
        function dt   = fdgTimesDrawn(this, varargin)
            dt = this.tableCaprac_.well.TIMEDRAWN_Hh_mm_ss;
            dt = dt(this.validSamples_);
            dt = dt - this.clockDurationOffsets(5);
            if (~isempty(varargin))
                dt = dt(varargin{:});
            end
        end
        function [tbl,this] = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfnXlsx', this.fqfilename, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});            
            
            % only the dates in tradmin are assumed correct;
            % spreadsheets auto-fill datetime cells with the date of data entry
            % which is typically not the date of measurement
            
            warning('off', 'MATLAB:table:ModifiedVarnames');
            tbl.tradmin = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Runs-2', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true); 
            tbl.well = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Runs', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            tbl.clocks0 = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Table 1', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', false, 'ReadRowNames', false);
            tbl.clocks = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            warning('on', 'MATLAB:table:ModifiedVarnames');
            
            this.timingData_.datetime0 = this.datetime(tbl.tradmin{1, 'ADMINistrationTime_Hh_mm_ss'});
            tbl.well.TIMEDRAWN_Hh_mm_ss = ...
                this.correctDateToReferenceDate( ...
                    this.datetime(tbl.well.TIMEDRAWN_Hh_mm_ss));
            this.tableCaprac_ = tbl;
            this.validSamples_ = ~isnat(tbl.well.TIMEDRAWN_Hh_mm_ss) & ...
                                 strcmp(tbl.well.TRACER, '[18F]DG');
            this.isPlasma = false;
        end
        function        save(~)
            error('mlpet:notImplemented', 'Caprac.save');
        end
        function this = shiftTimes(this, Dt)
            %% SHIFTTIMES provides time-coordinate transformation
            assert(isnumeric(Dt) && isscalar(Dt));
            this.timingData_ = this.timingData_.shiftTimes(Dt);
        end
        function v    = visibleVolume(this)
            mass = this.tableCaprac_.well.MassSample_G;
            mass = mass(this.validSamples_);
            v    = mass/mlpet.Blood.BLOODDEN;
            v    = ensureRowVector(v); % empirically measured on Caprac
        end
        
 		function this = Caprac(varargin)
 			%% CAPRAC
 			%  Usage:  this = Caprac()

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'scannerData', @(x) isa(x, 'mlpet.IScannerData'));
            addParameter(ip, 'manualData', @(x) isa(x, 'mldata.IManualMeasurements'));
            addParameter(ip, 'aifTimeShift', 0, @isnumeric);
            addParameter(ip, 'invEfficiency', 1, @isnumeric);
            parse(ip, varargin{:});
            
            this = this@mlpet.AbstractAifData(varargin{:});    
            this.fqfilename = this.sessionData.CCIRRadMeasurements;        
 			[~,this] = readtable(this); 
            this.scannerData_          = this.updatedScannerData;
            this.timingData_           = this.updatedTimingData;
            this.invEfficiency_     = ip.Results.invEfficiency;
            this.counts_               = this.tableCaprac2counts;
            this                       = this.shiftTimes(ip.Results.aifTimeShift);         
            this.specificActivity_      = this.tableCaprac2specificActivity;
            
            dc = mlpet.DecayCorrection.factoryFor(this);
            tshift = seconds(this.doseAdminDatetime - this.datetime0);
            if (tshift > 600) % KLUDGE
                warning('mpet:unexpectedParamValue', 'Caprac.ctor.tshift->%i', tshift);
                tshift = 0; 
            end 
            if (this.isDecayCorrected)
                this.specificActivity = dc.uncorrectedActivities(this.specificActivity, tshift);
            end
        end        
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        validSamples_
        tableCaprac_
    end

    methods (Access = protected)
        function dt_ = correctDateToReferenceDate(this, dt_)
            dt_ = this.xlsxObjScanData.correctDateToReferenceDate(dt_);
        end
        function d  = extractDateOnly(this, dt_)
            d = this.manualData_.extractDateOnly(dt_);
        end
        function dt_ = replaceDateOnly(this, dt_, d)
            dt_ = this.manualData_.replaceDataOnly(dt_, d);
        end
        function t  = tableCaprac2times(this)
            t = seconds(this.fdgTimesDrawn - this.fdgTimesDrawn(1));
            t = ensureRowVector(t);
        end
        function c  = tableCaprac2counts(this)
            c = 1000*this.tableCaprac_.well.W_01_Kcpm(this.validSamples_);
            c = ensureRowVector(c);
        end
        function b  = tableCaprac2specificActivity(this)
            b = (1000/60)*this.DACGe68*mlpet.AbstractHerscovitch1985.BRAIN_DENSITY;
            b = ensureRowVector(b);
        end
        function sd = updatedScannerData(this)
            adminDatetime = this.datetime(this.tableCaprac_.tradmin{7, 'ADMINistrationTime_Hh_mm_ss'});

            sd = this.scannerData_;
            sd.doseAdminDatetime = adminDatetime - this.clockDurationOffsets(5);
            sd.datetime0 = sd.datetime0 - this.clockDurationOffsets(1);
        end
        function td = updatedTimingData(this)
            td           = this.timingData_;
            td.times     = this.tableCaprac2times;
            td.datetime0 = this.replaceDateOnly(td.datetime0, this.extractDateOnly(this.fdgTimesDrawn(1)));
            td.time0     = td.datetime2sec(this.scannerData_.sec2datetime(this.scannerData_.time0));
            td.timeF     = td.datetime2sec(this.scannerData_.sec2datetime(this.scannerData_.timeF));
            td.dt        = min(td.taus);
        end
    end
    
    %% HIDDEN
    %  @deprecated
    
    properties (Hidden)        
        variableCountTime = nan
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


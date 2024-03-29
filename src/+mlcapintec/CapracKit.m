classdef (Sealed) CapracKit < handle & mlkinetics.InputFuncKit
    %% line1
    %  line2
    %  
    %  Created 09-Jun-2022 14:17:13 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlcapintec/src/+mlcapintec.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    properties (Dependent)
        decayCorrected % false for 15O
    end

    methods %% GET
        function g = get.decayCorrected(this)
            if isempty(this.device_)
                do_make_device(this);
            end
            g = this.device_.decayCorrected;
        end
    end

    methods
        function ic = do_make_activity(this, varargin)
            if isempty(this.device_)
                do_make_device(this);
            end
            a = this.device_.activity(varargin{:});
            ic = this.do_make_input_func(a);
        end
        function ic = do_make_activity_density(this, varargin)
            if isempty(this.device_)
                do_make_device(this);
            end
            a = this.device_.activityDensity(varargin{:});
            ic = this.do_make_input_func(a);
        end
        function ic = do_make_activity_density_interp1(this, varargin)
            if isempty(this.device_)
                do_make_device(this);
            end
            a = this.device_.activityDensityInterp1(varargin{:});
            ic = this.do_make_input_func(a);
        end
        function dev = do_make_device(this, varargin)
            if ~isempty(this.device_)
                dev = this.device_;
                return
            end

            this.device_ = this.buildCountingDevice(varargin{:});
            dev = this.device_;
        end
        function ic = do_make_input_func(this, measurement)
            arguments
                this mlcapintec.CapracKit
                measurement {mustBeNumeric,mustBeNonempty}
            end

            %% allow for revisions to device|data, such as decay-correction
            %if ~isempty(this.input_func_ic_)
            %    ic = this.input_func_ic_;
            %    return
            %end

            if isempty(this.device_)
                do_make_device(this);
            end

            if ~isempty(this.input_func_ic_)
                ic = this.input_func_ic_;
                return
            end

            med = this.bids_kit_.make_bids_med();
            ifc = copy(med.imagingFormat);
            ifc.img = measurement;
            ifc.fqfp = this.device_.new_fqfp();
            ifc.json_metadata.taus = this.device_.taus;
            ifc.json_metadata.times = this.device_.times;
            ifc.json_metadata.timesMid = this.device_.timesMid;
            ifc.json_metadata.timeUnit = "second";
            ic = mlfourd.ImagingContext2(ifc);
            %ic.addJsonMetadata(opts);
            this.input_func_ic_ = ic;
        end
    end

    methods (Static)
        function this = instance(varargin)
            this = mlkinetics.CapracKit();
            this.install_input_func(varargin{:})
            % persistent uniqueInstance
            % if (isempty(uniqueInstance))
            %     this = mlkinetics.CapracKit();
            %     this.install_input_func(varargin{:})
            %     uniqueInstance = this;
            % else
            %     this = uniqueInstance;
            %     this.install_input_func(varargin{:})
            % end
        end
    end 

    %% PROTECTED

    methods (Access = protected)
        function install_input_func(this, varargin)
            install_input_func@mlkinetics.InputFuncKit(this, varargin{:});
        end
    end

    %% PRIVATE

    methods (Access = private)
        function input_func_dev = buildCountingDevice(this, opts)
            arguments
                this mlcapintec.CapracKit
                opts.alignToScanner logical = false
                opts.sameWorldline logical = false
                opts.fqfileprefix {mustBeTextScalar} = ""
                opts.referenceDev = []
            end
            med = this.bids_kit_.make_bids_med();
            if isemptytext(opts.fqfileprefix)
                pth = med.imagingContext.filepath;
                fp = mlpipeline.Bids.adjust_fileprefix(med.imagingContext.fileprefix, ...                
                    new_proc=stackstr(use_dashes=true), new_mode="dev");
                opts.fqfileprefix = fullfile(pth, fp);
            end
            
            input_func_dev = mlcapintec.CapracDevice.createFromSession(med);
            input_func_dev.fqfileprefix = opts.fqfileprefix; 
            if ~isempty(scanner_dev) && opts.alignToScanner
                input_func_dev = input_func_dev.alignArterialToReference( ...
                    arterialDev=input_func_dev, ...
                    referenceDev=opts.referenceDev, ...
                    sameWorldline=opts.sameWorldline);
            end
        end
        function this = CapracKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end

classdef CapracBuilder < mlpet.IAifDataBuilder
	%% CAPRACBUILDER  

	%  $Revision$
 	%  was created 12-Dec-2017 16:32:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlcapintec/src/+mlcapintec.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = CapracBuilder(varargin)
 			%% CAPRACBUILDER
            
            ip = inputParser;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlraichle.SessionData'));
            addParameter(ip, 'dtNyquist', @isnumeric);
            parse(ip, varargin{:});
 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end


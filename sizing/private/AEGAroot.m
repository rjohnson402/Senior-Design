function root = AEGAroot()
% Resolve data and output folders relative to the public entry points.
root = fileparts(fileparts(mfilename('fullpath')));
end

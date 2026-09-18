function [Dprop, Adisc, station, span] = AEGAprop(msn, SW)
%AEGAPROP  Propeller diameter and disc area from span packing.
%
%   [Dprop, Adisc, station, span] = AEGAprop(msn, SW)
%
%   Single source for propeller geometry. AEGAsize and blow_wind(maybe) both call
%   this so they cannot disagree. Previously AEGAsize used a fixed
%   msn.Dprop = 2.43 ft while blow_wind derived 3.31 ft from the same
%   design: a 46 percent error in disc area, invisible in both printouts.
%
%   station  span available per propulsor, (b - fuselage width)/N
%   Dprop    msn.fill times that, so adjacent discs do not overlap
%
%   UNITS: ft, ft^2.

span    = sqrt(msn.AR*SW);
station = (span - msn.WFus)/msn.NPROP;
Dprop   = msn.fill*station;
Adisc   = msn.NPROP*pi*(Dprop/2)^2;
end
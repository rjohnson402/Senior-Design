function lines = AEGAtradetitle2035(name,m,detail)
% Compact, input-derived captions shared by the presentation figures.
lines = {name, sprintf('%.0f nm at %.0f KTAS + %.0f min reserve | %.0f lb payload | %.0f Wh/kg pack, %.0f%% usable', ...
    m.range,m.Vkt,m.reserve,m.payload,m.whkg,100*m.fusable),char(detail)};
end

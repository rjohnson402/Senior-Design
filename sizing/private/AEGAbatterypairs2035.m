function pairs = AEGAbatterypairs2035(m)
% Motor order [L1 L2 L3 L4 R1 R2 R3 R4], with L4/R4 cruise motors.
% Empty/missing mapping preserves historical mirrored isolated pairs.
pairs=[1 5;2 6;3 7;4 8];
if isfield(m,'battery_motor_pairs') && ~isempty(m.battery_motor_pairs)
    pairs=m.battery_motor_pairs;
end
validateattributes(pairs,{'numeric'},{'size',[4 2],'integer','>=',1,'<=',8});
assert(isequal(sort(pairs(:)),(1:8)'), ...
    'AEGAbatterypairs2035:partition','Each motor must belong to exactly one battery bank.');
end

function v = pick(s, name, default)
    %PICK  Return s.(name) if the caller supplied it, otherwise the default.
    if isfield(s, name) && ~isempty(s.(name))
        v = s.(name);
    else
        v = default;
    end
end
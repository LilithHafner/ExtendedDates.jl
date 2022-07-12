using Dates: CONVERSION_SPECIFIERS, compute_dateformat_regex,
    tryparsenext_base10, min_width, max_width, DatePart

function __init__()
    CONVERSION_SPECIFIERS['t'] = Month # Semester
    CONVERSION_SPECIFIERS['q'] = Month # Quarter
    CONVERSION_SPECIFIERS['w'] = Day # Week
end

# TODO: this behavior is strange for weeks
for (c, n) ∈ [('t', 6), ('q', 3), ('w', 7)]
    @eval function Dates.tryparsenext(d::DatePart{$c}, str, i, len)
        x = tryparsenext_base10(str, i, len, min_width(d), max_width(d))
        x isa Tuple{Integer, Integer} ? ($n*x[1]-$(n-1), x[2]) : x
    end
end

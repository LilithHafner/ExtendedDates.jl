using Dates: DATEFORMAT_REGEX_LOCK, DATEFORMAT_REGEX_CACHE, DATEFORMAT_REGEX_HASH,
    CONVERSION_SPECIFIERS, compute_dateformat_regex,
    tryparsenext_base10, min_width, max_width, DatePart

function __init__()
    lock(DATEFORMAT_REGEX_LOCK) do
        CONVERSION_SPECIFIERS['t'] = Month # Semester
        CONVERSION_SPECIFIERS['q'] = Month # Quarter
        CONVERSION_SPECIFIERS['w'] = Day # Week

        DATEFORMAT_REGEX_HASH[] = hash(keys(CONVERSION_SPECIFIERS))
        DATEFORMAT_REGEX_CACHE[] = compute_dateformat_regex(CONVERSION_SPECIFIERS)
    end
end

# TODO: this behavior is strange for weeks
for (c, n) ∈ [('t', 6), ('q', 3), ('w', 7)]
    @eval function Dates.tryparsenext(d::DatePart{$c}, str, i, len)
        x = tryparsenext_base10(str, i, len, min_width(d), max_width(d))
        x isa Tuple{Integer, Integer} ? ($n*x[1]-$(n-1), x[2]) : x
    end
end

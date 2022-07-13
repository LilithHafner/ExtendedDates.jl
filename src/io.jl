# Not a real TimeType, just a hack to reuse Dates.tryparsenext_internal
struct RenameMePeriod <: TimeType end

function __init__()
    Dates.CONVERSION_SPECIFIERS['P'] = Period
    Dates.CONVERSION_TRANSLATIONS[RenameMePeriod] = (Year, Period)
    Dates.CONVERSION_DEFAULTS[Period] = 1
    @eval Dates.default_format(::Type{Day}) = dateformat"yyyy-\DP"
    @eval Dates.default_format(::Type{Week}) = dateformat"yyyy-\WP"
    @eval Dates.default_format(::Type{Month}) = dateformat"yyyy-PP"
    @eval Dates.default_format(::Type{Quarter}) = dateformat"yyyy-QP"
    @eval Dates.default_format(::Type{Semester}) = dateformat"yyyy-\SP"
    @eval Dates.default_format(::Type{Year}) = dateformat"yyyy"
end

Dates.tryparsenext(d::Dates.DatePart{'P'}, str, i, len) =
    Dates.tryparsenext_base10(str, i, len, Dates.min_width(d), Dates.max_width(d))

Dates.format(io::IO, d::Dates.DatePart{'P'}, p::Period) = print(io, lpad(subperiod(p), d.width, '0'))

function Base.parse(::Type{T}, str::AbstractString, df::DateFormat=Dates.default_format(T)) where T<:Period
    pos, len = firstindex(str), lastindex(str)
    val = Dates.tryparsenext_internal(RenameMePeriod, str, pos, len, df, true)
    @assert val !== nothing
    values, endpos = val
    return period(T, values...)::T
end

function Dates.format(io::IO, dt::Period, fmt::DateFormat)
    for token in fmt.tokens
        Dates.format(io, token, dt, fmt.locale)
    end
end

function Dates.format(dt::Period, fmt::DateFormat=Dates.default_format(typeof(dt)), bufsize=12)
    # preallocate to reduce resizing
    io = IOBuffer(Vector{UInt8}(undef, bufsize), read=true, write=true)
    Dates.format(io, dt, fmt)
    String(io.data[1:io.ptr - 1])
end

function Dates.format(dt::Period, f::AbstractString; locale::Dates.Locale=ENGLISH)
    Dates.format(dt, DateFormat(f, locale))
end

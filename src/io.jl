# Not a real TimeType, just a hack to reuse Dates.tryparsenext_internal
struct RenameMePeriod <: TimeType end

function __init__()
    Dates.CONVERSION_SPECIFIERS['P'] = Period
    Dates.CONVERSION_TRANSLATIONS[RenameMePeriod] = (Year, Period, Month, Day)
    Dates.CONVERSION_DEFAULTS[Period] = 1
    @eval Dates.default_format(::Type{Period}) = [
        dateformat"YYYY" => Year,
        dateformat"YYYY-\Y" => Year,
        dateformat"YYYY-\YP" => Year,
        dateformat"YYYY-\y" => Year,
        dateformat"YYYY-\yP" => Year,
        dateformat"YYYY-PPP" => Day,
        dateformat"YYYY-\DP" => Day,
        dateformat"YYYY-\dP" => Day,
        dateformat"YYYY-\WP" => Week,
        dateformat"YYYY-\wP" => Week,
        dateformat"YYYY-\MPP" => Month,
        dateformat"YYYY-\mPP" => Month,
        dateformat"YYYY-QP" => Quarter,
        dateformat"YYYY-qP" => Quarter,
        dateformat"YYYY-\SP" => Semester,
        dateformat"YYYY-\sP" => Semester,
        dateformat"YYYY-mm-dd" => Day,
    ]

    @eval Dates.default_format(::Type{Day}) = dateformat"YYYY-mm-dd"
    @eval Dates.default_format(::Type{Week}) = dateformat"YYYY-\WP"
    @eval Dates.default_format(::Type{Month}) = dateformat"YYYY-\MPP"
    @eval Dates.default_format(::Type{Quarter}) = dateformat"YYYY-QP"
    @eval Dates.default_format(::Type{Semester}) = dateformat"YYYY-\SP"
    @eval Dates.default_format(::Type{Year}) = dateformat"YYYY"
end

Dates.tryparsenext(d::Dates.DatePart{'P'}, str, i, len) =
    Dates.tryparsenext_base10(str, i, len, Dates.min_width(d), Dates.max_width(d))

Dates.format(io::IO, d::Dates.DatePart{'P'}, p::Period) = print(io, lpad(subperiod(p), d.width, '0'))

function Base.tryparse(::Type{T}, str::AbstractString,
                       df::DateFormat=Dates.default_format(T), raise=false) where T<:Period
    pos, len = firstindex(str), lastindex(str)
    res = Dates.tryparsenext_internal(RenameMePeriod, str, pos, len, df, raise)
    res === nothing && return nothing
    (y, p, m, d), _ = res
    # manual union splitting to avoid dynamic dispatch
    if T == Day && (m != 1 || d != 1)
        !raise && validargs(T, y, m, d) !== nothing && return nothing
        period(T, y, m, d)::T
    else
        !raise && validargs(T, y, p) !== nothing && return nothing
        period(T, y, p)::T
    end
end
function Base.parse(::Type{T}, str::AbstractString,
                    df::DateFormat=Dates.default_format(T)) where T<:Period
    tryparse(T, str, df, true)
end
function Base.tryparse(::Type{Period}, str::AbstractString,
                       dfs=Dates.default_format(Period))
    for (df, P) in dfs
        res = tryparse(P, str, df)
        res !== nothing && return res
    end
end
function Base.parse(::Type{Period}, str::AbstractString, dfs=Dates.default_format(Period))
    res = tryparse(Period, str, dfs)
    res === nothing && throw(ArgumentError("No matching date format found"))
    res
end
function Base.parse(::Type{Tuple{Period, DateFormat}}, str::AbstractString, dfs=Dates.default_format(Period))
    for (df, P) in dfs
        res = tryparse(P, str, df)
        res !== nothing && return res, df
    end
end
function Base.parse(::Type{Vector{<:Period}}, strs::AbstractVector{<:AbstractString}, dfs=Dates.default_format(Period))
    parse_periods(strs, dfs)
end
function parse_periods(strs, dfs=Dates.default_format(Period))
    si = iterate(strs)
    si === nothing && return Period[]
    p, df = parse(Tuple{Period, DateFormat}, first(si), dfs)
    parse_periods!([p], Iterators.drop(strs, 1), df)
end
function parse_periods!(v, strs, df)
    for str in strs
        push!(v, parse(eltype(v), str, df))
    end
    v
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

# Not a real TimeType, just a hack to reuse Dates.tryparsenext_internal
struct RenameMePeriod <: TimeType end

function __init__()
    Dates.CONVERSION_SPECIFIERS['P'] = Period
    Dates.CONVERSION_TRANSLATIONS[RenameMePeriod] = (Year, Period, Month, Day)
    Dates.CONVERSION_DEFAULTS[Period] = 1
    @eval Dates.default_format(::Type{PeriodSE}) = [
        dateformat"YYYY" => YearSE,
        dateformat"YYYY-\Y" => YearSE,
        dateformat"YYYY-\YP" => YearSE,
        dateformat"YYYY-\y" => YearSE,
        dateformat"YYYY-\yP" => YearSE,
        dateformat"YYYY-PPP" => DaySE,
        dateformat"YYYY-\DP" => DaySE,
        dateformat"YYYY-\dP" => DaySE,
        dateformat"YYYY-\WP" => WeekSE,
        dateformat"YYYY-\wP" => WeekSE,
        dateformat"YYYY-\MPP" => MonthSE,
        dateformat"YYYY-\mPP" => MonthSE,
        dateformat"YYYY-QP" => QuarterSE,
        dateformat"YYYY-qP" => QuarterSE,
        dateformat"YYYY-\SP" => SemesterSE,
        dateformat"YYYY-\sP" => SemesterSE,
        dateformat"YYYY-mm-dd" => DaySE,
    ]

    @eval Dates.default_format(::Type{DaySE}) = dateformat"YYYY-mm-dd"
    @eval Dates.default_format(::Type{WeekSE}) = dateformat"YYYY-\WP"
    @eval Dates.default_format(::Type{MonthSE}) = dateformat"YYYY-\MPP"
    @eval Dates.default_format(::Type{QuarterSE}) = dateformat"YYYY-QP"
    @eval Dates.default_format(::Type{SemesterSE}) = dateformat"YYYY-\SP"
    @eval Dates.default_format(::Type{YearSE}) = dateformat"YYYY"
end

Dates.tryparsenext(d::Dates.DatePart{'P'}, str, i, len) =
    Dates.tryparsenext_base10(str, i, len, Dates.min_width(d), Dates.max_width(d))

Dates.format(io::IO, d::Dates.DatePart{'P'}, p::PeriodSE) = print(io, lpad(subperiod(p), d.width, '0'))

function Base.tryparse(::Type{UTInstant{T}}, str::AbstractString,
                       df::DateFormat=Dates.default_format(T), raise=false) where T<:Period
    pos, len = firstindex(str), lastindex(str)
    res = Dates.tryparsenext_internal(RenameMePeriod, str, pos, len, df, raise)
    res === nothing && return nothing
    (y, p, m, d), _ = res
    # manual union splitting to avoid dynamic dispatch
    if T == Day && (m != 1 || d != 1)
        !raise && validargs(T, y, m, d) !== nothing && return nothing
        period(T, y, m, d)::UTInstant{T}
    else
        !raise && validargs(T, y, p) !== nothing && return nothing
        period(T, y, p)::UTInstant{T}
    end
end
function Base.parse(::Type{UTInstant{T}}, str::AbstractString,
                    df::DateFormat=Dates.default_format(UTInstant{T})) where T<:Period
    tryparse(UTInstant{T}, str, df, true)
end
function Base.tryparse(::Type{PeriodSE}, str::AbstractString,
                       dfs=Dates.default_format(PeriodSE))
    for (df, P) in dfs
        res = tryparse(P, str, df)
        res !== nothing && return res
    end
end
function Base.parse(::Type{PeriodSE}, str::AbstractString, dfs=Dates.default_format(PeriodSE))
    res = tryparse(PeriodSE, str, dfs)
    res === nothing && throw(ArgumentError("No matching date format found"))
    res
end
function Base.parse(::Type{Tuple{PeriodSE, DateFormat}}, str::AbstractString, dfs=Dates.default_format(PeriodSE))
    for (df, P) in dfs
        res = tryparse(P, str, df)
        res !== nothing && return res, df
    end
end
function Base.parse(::Type{Vector{<:PeriodSE}}, strs::AbstractVector{<:AbstractString}, dfs=Dates.default_format(PeriodSE))
    parse_periods(strs, dfs)
end
function parse_periods(strs, dfs=Dates.default_format(PeriodSE))
    si = iterate(strs)
    si === nothing && return PeriodSE[]
    p, df = parse(Tuple{PeriodSE, DateFormat}, first(si), dfs)
    parse_periods!([p], Iterators.drop(strs, 1), df)
end
function parse_periods!(v, strs, df)
    for str in strs
        push!(v, parse(eltype(v), str, df))
    end
    v
end

function Dates.format(io::IO, dt::PeriodSE, fmt::DateFormat)
    for token in fmt.tokens
        Dates.format(io, token, dt, fmt.locale)
    end
end

function Dates.format(dt::PeriodSE, fmt::DateFormat=Dates.default_format(typeof(dt)), bufsize=12)
    # preallocate to reduce resizing
    io = IOBuffer(Vector{UInt8}(undef, bufsize), read=true, write=true)
    Dates.format(io, dt, fmt)
    String(io.data[1:io.ptr - 1])
end

function Dates.format(dt::PeriodSE, f::AbstractString; locale::Dates.Locale=ENGLISH)
    Dates.format(dt, DateFormat(f, locale))
end

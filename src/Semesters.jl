## types.jl
struct Semester <: DatePeriod
    value::Int64
    Semester(v::Number) = new(v)
end


## periods.jl

# The style of this let statement is a bit odd because
# the body is a verbatim copy of Dates/src/periods.jl
let period = :Semester
    period_str = string(period)
    accessor_str = lowercase(period_str)
    # Convenience method for show()
    @eval _units(x::$period) = " " * $accessor_str * (abs(value(x)) == 1 ? "" : "s")
    if VERSION < v"1.9.0-DEV.1160"
        # periodisless
        @eval Dates.periodisless(x::$period, y::$period) = value(x) < value(y)
    end
    # AbstractString parsing (mainly for IO code)
    @eval $period(x::AbstractString) = $period(Base.parse(Int64, x))
    # The period type is printed when output, thus it already implies its own typeinfo
    @eval Base.typeinfo_implicit(::Type{$period}) = true
    # Period accessors
    typs = period in (:Microsecond, :Nanosecond) ? ["Time"] :
        period in (:Hour, :Minute, :Second, :Millisecond) ? ["Time", "DateTime"] : ["Date", "DateTime"]
    reference = period === :Week ? " For details see [`$accessor_str(::Union{Date, DateTime})`](@ref)." : ""
    for typ_str in typs
        @eval begin
            @doc """
                $($period_str)(dt::$($typ_str)) -> $($period_str)

            The $($accessor_str) part of a $($typ_str) as a `$($period_str)`.$($reference)
            """ $period(dt::$(Symbol(typ_str))) = $period($(Symbol(accessor_str))(dt))
        end
    end
    @eval begin
        @doc """
            $($period_str)(v)

        Construct a `$($period_str)` object with the given `v` value. Input must be
        losslessly convertible to an [`Int64`](@ref).
        """ $period(v)
    end
end

if VERSION < v"1.9.0-DEV.1160"
    Dates.periodisless(::Period,::Semester) = true
    Dates.periodisless(::Year,::Semester) = false
    Dates.periodisless(::Quarter,::Semester) = true
    Dates.periodisless(::Month,::Semester) = true
    Dates.periodisless(::Week,::Semester) = true
    Dates.periodisless(::Day,::Semester) = true
end

for (n, Small, Large) in [(2, Semester, Year), (2, Quarter, Semester), (6, Month, Semester)]
    @eval function convert(::Type{$Small}, x::$Large)
        $(typemin(Int64) ÷ n) ≤ value(x) ≤ $(typemax(Int64) ÷ n) || throw(InexactError(:convert, $Small, x))
        $Small(value(x) * $n)
    end
    @eval convert(::Type{$Large}, x::$Small) = $Large(Dates.divexact(value(x), $n))
    @eval promote_rule(::Type{$Large}, ::Type{$Small}) = $Small
end

(==)(x::Dates.FixedPeriod, y::Semester) = iszero(x) & iszero(y)
(==)(x::Semester, y::Dates.FixedPeriod) = y == x

if VERSION < v"1.9.0-DEV.1225"
    @eval otherperiod_seed(x) = iszero(value(x)) ? Dates.zero_or_fixedperiod_seed : Dates.nonzero_otherperiod_seed
else
    using Dates: otherperiod_seed
end
hash(x::Semester, h::UInt) = hash(6 * value(x), h + otherperiod_seed(x))

if VERSION < v"1.9.0-DEV.902"
    @eval toms(c::Semester) = 86400000.0 * 182.62125 * value(c)
end
days(c::Semester) = 182.62125 * value(c)


## accessors.jl
"""
    semester(dt::TimeType) -> Int64

The semester of a `Date` or `DateTime` as an [`Int64`](@ref).
"""
semester(days) = month(days) < 7 ? 1 : 2
semester(dt::TimeType) = semester(days(dt))


## adjusters.jl
Base.trunc(dt::Date, ::Type{Semester}) = firstdayofsemester(dt)
Base.trunc(dt::DateTime, ::Type{Semester}) = DateTime(trunc(Date(dt), Semester))

"""
    firstdayofsemester(dt::TimeType) -> TimeType

Adjusts `dt` to the first day of its semester.

# Examples
```jldoctest
julia> ExtendedDates.firstdayofsemester(DateTime("1996-05-20"))
1996-01-01T00:00:00

julia> ExtendedDates.firstdayofsemester(DateTime("1996-08-20"))
1996-07-01T00:00:00
```
"""
function firstdayofsemester(dt::Date)
    y,m = yearmonth(dt)
    mm = m < 7 ? 1 : 7
    return Date(y, mm, 1)
end
firstdayofsemester(dt::DateTime) = DateTime(firstdayofsemester(Date(dt)))

"""
    lastdayofsemester(dt::TimeType) -> TimeType

Adjusts `dt` to the last day of its semester.

# Examples
```jldoctest
julia> ExtendedDates.lastdayofsemester(DateTime("1996-05-20"))
1996-06-30T00:00:00

julia> ExtendedDates.lastdayofsemester(DateTime("1996-08-20"))
1996-12-31T00:00:00
```
"""
function lastdayofsemester(dt::Date)
    y,m = yearmonth(dt)
    mm, d = m < 7 ? (6, 30) : (12, 31)
    return Date(y, mm, d)
end
lastdayofsemester(dt::DateTime) = DateTime(lastdayofsemester(Date(dt)))


## arithmetic.jl
(+)(x::Date, y::Semester) = x + Month(y)
(-)(x::Date, y::Semester) = x - Month(y)
(+)(x::DateTime, y::Semester) = x + Month(y)
(-)(x::DateTime, y::Semester) = x - Month(y)


## query.jl
"""
    semesterofyear(dt::TimeType) -> Int

Return the semester that `dt` resides in. Range of value is 1:2.
"""
semesterofyear(dt::TimeType) = semester(dt)


const SEMESTERDAYS = (0, 31, 59, 90, 120, 151, 0, 31, 62, 92, 123, 153)

"""
    dayofsemester(dt::TimeType) -> Int

Return the day of the current semester of `dt`. Range of value is 1:184.
"""
function dayofsemester(dt::TimeType)
    (y, m, d) = yearmonthday(dt)
    return SEMESTERDAYS[m] + d + (2 < m < 7 && isleapyear(y))
end


## rounding.jl
Base.floor(dt::Date, p::Semester) = floor(dt, Month(p))

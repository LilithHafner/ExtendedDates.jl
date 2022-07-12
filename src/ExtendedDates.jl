module ExtendedDates

using Reexport
@reexport using Dates

import Base: +, -, isfinite, isless, :, print, show, ==, hash, convert, promote_rule
import Dates: Date, year, periodisless, toms, days, _units, periodisless, value, validargs

export period, frequency, subperiod, Undated,
    Semester, semesterofyear, dayofsemester, firstdayofsemester, lastdayofsemester

include("Semesters.jl")

const YearPeriod = Union{Month, Quarter, Semester, Year}

# Defining the epochs
"""
    epoch(::Type{Period})

The canonical epoch of a given type of period. For most period types the epoch is 
Saturday, January 1, year 0. For week periods, it is Monday, January 3, year 0.

```jldoctest
julia> ExtendedDates.epoch(Quarter)
0000-01-01

julia> ExtendedDates.epoch(Week)
0000-01-03
```
"""
epoch(::Type{<:Period}) = Date(0)
epoch(::Type{Week}) = Date(0, 1, 3) # Monday

# Constructors
"""
    period(::Type{<:Period}, year::Integer, subperiod::Integer = 1)

Construct a period from a year, subperiod, and frequency.

These periods are represented as an Int64 number of periods since an epoch defined by the
[`ExtendedDates.epoch`](@ref) function. For most period types the epoch is Saturday,
January 1, year 0. For week periods, it is Monday, January 3, year 0.

```jldoctest
julia> x = period(Semester, 2022, 1)
ExtendedDates.UTInstant(Semester(4044))

julia> println(x)
2022-S1

julia> Date(x)
2022-01-01

julia> Date(period(Week, 0))
0000-01-03

julia> Date(period(Day, 0))
0000-01-01
```
"""
function period(P::Type{<:Period}, year::Integer, subperiod::Integer = 1)
    err = validargs(P, year, subperiod)
    err === nothing || throw(err)
    return period(P, year, subperiod, nothing)
end

periodsinyear(P::Type{<:YearPeriod}) = Year(1) ÷ P(1)
period(P::Type{<:Period}, year, subperiod, unchecked) = 
    P(cld((Date(year) - epoch(P)), P(1)) + subperiod - 1)
period(P::Type{<: YearPeriod}, year, subperiod, unchecked) =
    P(periodsinyear(P) * year + subperiod - 1)

function validargs(P::Type{<:YearPeriod}, ::Int64, p::Int64)
    0 < p <= periodsinyear(P) || return ArgumentError("$P: $p out of range (1:$(periodsinyear(P)))")
    nothing
end
function validargs(::Type{Day}, y::Int64, p::Int64)
    0 < p <= daysinyear(y) || return ArgumentError("$P: $p out of range (1:$(daysinyear(P))) for $y")
    nothing
end
function validargs(P::Type{<:Period}, y::Int64, p::Int64) # TODO inefficient
    year(Date(period(P, y, p, nothing))) == year(Date(period(P, y, 1, nothing))) || return ArgumentError("$P: $p out of range for $y")
    nothing
end

# Conversion to Date to calculate year and subperiod
Date(p::P) where P <: Period = epoch(P) + p

# Fallback accessors for frequency, year, subperiod
const frequency = oneunit
"""
    year(::UTInstant{<:Period})

The year of a period.

```jldoctest
julia> year(period(Day, 1960, 12))
1960
```
"""
year(p::Period) = year(Date(p))
"""
    year(::UTInstant{<:Period})

The subperiod of a period within a year. Numbering starts at one.

```jldoctest
julia> subperiod(period(Day, 1960, 12))
12

julia> Date(period(Day, 1960, 12))
1960-01-12
```
"""
subperiod(p::Period) = fld((Date(p) - floor(Date(p), Year)), frequency(p)) + 1

# Avoid conversion to Date for Year based periods
year(p::YearPeriod) = fld(p, Year(1))
subperiod(p::YearPeriod) = (rem(p, Year(1), RoundDown)) ÷ frequency(p) + 1

# print (for conversion to human readable/standard form string)
prefix(::Type{Semester}) = 'S'
prefix(::Type{Quarter}) = 'Q'
prefix(::Type{Week}) = 'W'
prefix(::Type{Day}) = 'D'
prefix(P::Period) = prefix(typeof(P))
format(io::IO, p::Period) = print(io, year(p), '-', prefix(p), subperiod(p))
format(io::IO, p::Year) = print(io, year(p))
format(io::IO, p::Month) = print(io, year(p), '-', lpad(subperiod(p), 2, '0'))
function format(p::Period)
    buf = IOBuffer()
    format(buf, p)
    return String(take!(buf))
end
format(i::Int64) = string(i)
Dates.format(p::Period) = format(p)

const Undated = Int64

# Convenience function for range of periods
(:)(start::P, stop::P) where P <: Period = start:oneunit(P):stop

include("io.jl")

end

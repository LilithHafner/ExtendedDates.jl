module ExtendedDates

using Reexport
@reexport using Dates

import Base: +, -, isfinite, isless, :, print, show, ==, hash, convert, promote_rule
import Dates: Date, year, periodisless, toms, days, _units, periodisless, value

export period, frequency, subperiod, Undated,
    Semester, semesterofyear, dayofsemester, firstdayofsemester, lastdayofsemester

include("Semesters.jl")

# Not `using Dates: UTInstant` to avoid type piracy
struct UTInstant{P<:Period} <: Dates.Instant
    periods::P
end
value(a::UTInstant) = value(a.periods)
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

# Non overflow checking constructors
"""
    period(::Type{<:Period}, year::Integer, subperiod::Integer = 1)

Construct a period from a year, subperiod, and frequency.

These periods are represented as an Int64 number of periods since an epoch defined by the
`ExtendedDates.epoch` function. For most period types the epoch is Saturday, January 1, 
year 0. For week periods, it is Monday, January 3, year 0.

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
period(P::Type{<:Period}, year::Integer, subperiod::Integer=1) =
    UTInstant(P((Date(year) - epoch(P)) ÷ P(1) + subperiod - 1))
period(P::Type{<:YearPeriod}, year::Integer, subperiod::Integer=1) =
    UTInstant(P(Year(1) ÷ P(1) * year + subperiod - 1))

# Conversion to Date to calculate year and subperiod
Date(p::UTInstant) = Date(0) + p.periods
Date(p::UTInstant{Week}) = Date(0, 1, 3) + p.periods

# Fallback accessors for frequency, year, subperiod
"""
    frequency(::UTInstant{<:Period})

The frequency of a period.

```jldoctest
julia> frequency(period(Year, 1960))
1 year
```
"""
frequency(::UTInstant{P}) where P <: Period = oneunit(P)
"""
    year(::UTInstant{<:Period})

The year of a period.

```jldoctest
julia> year(period(Day, 1960, 12))
1960
```
"""
year(p::UTInstant) = year(Date(p))
"""
    year(::UTInstant{<:Period})

The subperiod of a period within a year. Numbering starts at one.

```jldoctest
julia> subperiod(period(Day, 1960, 12))
12

julia> Date(period(Day, 1960, 12))
1960-01-12

julia> 1+1
3
```
"""
subperiod(p::UTInstant) = cld((Date(p) - floor(Date(p), Year)), frequency(p)) + 1

# Avoid conversion to Date for Year based periods
year(p::UTInstant{<:YearPeriod}) = p.periods ÷ Year(1)
subperiod(p::UTInstant{<:YearPeriod}) = (p.periods % Year(1)) ÷ frequency(p) + 1

# Arithmetic and comparison (for ranges)
isless(a::UTInstant, b::UTInstant) = isless(a.periods, b.periods)
(+)(a::UTInstant, b::Period) = UTInstant(a.periods + b)
(-)(a::UTInstant, b::Period) = UTInstant(a.periods - b)
isfinite(a::UTInstant) = true # Due to julia bug, fix in #45646
(:)(start::UTInstant{P}, stop::UTInstant{P}) where {P} = start:P(1):stop

# print (for conversion to human readable/standard form string)
prefix(::Type{Semester}) = 'S'
prefix(::Type{Quarter}) = 'Q'
prefix(::Type{Week}) = 'W'
prefix(::Type{Day}) = 'D'
print(io::IO, p::UTInstant{P}) where P = print(io, year(p), '-', prefix(P), subperiod(p))
print(io::IO, p::UTInstant{Year}) = print(io, year(p))
print(io::IO, p::UTInstant{Month}) = print(io, year(p), '-', lpad(subperiod(p), 2, '0'))

# show
function show(io::IO, p::UTInstant) 
    print(io, UTInstant, '(')
    show(io, p.periods)
    print(io, ')')
end

# Undated
struct Undated <: Dates.AbstractTime
    value::Int
end
value(a::Undated) = a.value
isless(a::Undated, b::Undated) = isless(a.value, b.value)
(+)(a::Undated, b::Integer) = Undated(a.value + b)
(-)(a::Undated, b::Integer) = Undated(a.value - b)
(-)(a::Undated, b::Undated) = a.value - b.value
isfinite(a::Undated) = true # Due to julia bug, fix in #45646

end

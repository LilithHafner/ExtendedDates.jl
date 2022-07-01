module ExtendedDates

using Reexport
@reexport using Dates
using Dates: value

import Base: +, -, isfinite, isless, :, print, show, ==, hash, convert, promote_rule
import Dates: Date, year, periodisless, toms, days, _units, periodisless

export period, frequency, subperiod, Undated, Semester

include("Semesters.jl")

# Not `using Dates: UTInstant` to avoid type piracy
struct UTInstant{P<:Period} <: Dates.Instant
    periods::P
end
const YearPeriods = Union{Month, Quarter, Semester, Year}
const DayPeriods = Union{Week, Day}

# Defining the epochs
epoch(::Type{<:Period}) = Date(0)
epoch(::Type{Week}) = Date(0, 1, 3) # Monday

# Non overflow checking constructors
period(P::Type{<:Period}, year::Integer) = period(P, year, 1)
period(P::Type{<:YearPeriods}, year::Integer, subperiod::Integer) = 
    UTInstant(P(Year(1) ÷ P(1) * year + subperiod - 1))
period(P::Type{<:DayPeriods}, year::Integer, subperiod::Integer) =
    UTInstant(P((Date(year) - epoch(P)) ÷ P(1) + subperiod))

# Conversion to Date to calculate year and subperiod
Date(p::UTInstant) = Date(0) + p.periods
Date(p::UTInstant{Week}) = Date(0, 1, 3) + p.periods

# Fallback accessors for frequency, year, subperiod
frequency(::UTInstant{P}) where P <: Period = oneunit(P)
year(p::UTInstant) = year(Date(p))
subperiod(p::UTInstant) = cld((Date(p) - floor(Date(p), Year)), frequency(p))

# Avoid conversion to Date for Year based periods
year(p::UTInstant{<:YearPeriods}) = p.periods ÷ Year(1)
subperiod(p::UTInstant{<:YearPeriods}) = (p.periods % Year(1)) ÷ frequency(p) + 1

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
isless(a::Undated, b::Undated) = isless(a.value, b.value)
(+)(a::Undated, b::Integer) = Undated(a.value + b)
(-)(a::Undated, b::Integer) = Undated(a.value - b)
(-)(a::Undated, b::Undated) = a.value - b.value
isfinite(a::Undated) = true # Due to julia bug, fix in #45646

end

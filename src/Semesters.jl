struct Semester <: DatePeriod
    value::Int64
    Semester(v::Number) = new(v)
end

# The style of this let statement is a bit odd because 
# the body is a verbatim copy of Dates/src/periods.jl
let period = :Semester
    period_str = string(period)
    accessor_str = lowercase(period_str)
    # Convenience method for show()
    @eval _units(x::$period) = " " * $accessor_str * (abs(value(x)) == 1 ? "" : "s")
    # periodisless
    @eval periodisless(x::$period, y::$period) = value(x) < value(y)
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

periodisless(::Period,::Semester) = true
periodisless(::Semester,::Year) = false
periodisless(::Quarter,::Semester) = true
periodisless(::Month,::Semester) = true
periodisless(::Week,::Semester) = true
periodisless(::Day,::Semester) = true

for (n, Small, Large) in [(2, Semester, Year), (2, Quarter, Semester), (6, Month, Semester)]
    @eval function convert(::Type{$Small}, x::$Large)
        $(typemin(Int64) ÷ n) ≤ value(x) ≤ $(typemax(Int64) ÷ n) || throw(InexactError(:convert, $Small, x))
        $Small(value(x) * $n)
    end
    @eval convert(::Type{$Large}, x::$Small) = $Large(divexact(value(x), $n))
    @eval promote_rule(::Type{$Large}, ::Type{$Small}) = $Small
end

(==)(x::Dates.FixedPeriod, y::Semester) = iszero(x) & iszero(y)
(==)(x::Semester, y::Dates.FixedPeriod) = y == x

otherperiod_seed(x) = iszero(value(x)) ? Dates.zero_or_fixedperiod_seed : Dates.nonzero_otherperiod_seed
hash(x::Semester, h::UInt) = hash(3 * value(x), h + otherperiod_seed(x))

toms(c::Semester) = 86400000.0 * 182.62125 * value(c)
days(c::Semester) = 182.62125 * value(c)

# TODO add fuller support for interaction between Semesters and other Periods

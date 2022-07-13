using ExtendedDates
using Test
using InteractiveUtils: subtypes

### Represent periods (time intervals) of different frequencies: year 2022, 2nd quarter of 200, …
### Constructors with (year, subperiod, frequency)
year_2022 = period(Year, 2022)
second_quarter_of_200 = period(Quarter, 200, 2)
third_week_of_1935 = period(Week, 1935, 3)
hundredth_day_of_year_54620 = period(Day, 54620, 100)
second_semester_of_2022 = period(Semester, 2022, 2)
undated_12 = Undated(12)
@test_throws ArgumentError("Month: 13 out of range (1:12)") period(Month, 1729, 13)

### Periods can be identified by (year, subperiod, frequency)

@testset "year" begin
    @test year(year_2022) == 2022
    @test year(second_quarter_of_200) == 200
    @test year(third_week_of_1935) == 1935
    @test year(hundredth_day_of_year_54620) == 54620
    @test year(second_semester_of_2022) == 2022
    @test_broken year(undated_12) == 12 # years(x::Int) assumes x is measured in days. We want an error. It would take a breaking changed to stdlib to fix this. TODO: try
end

@testset "subperiod" begin
    @test subperiod(year_2022) == 1
    @test subperiod(second_quarter_of_200) == 2
    @test subperiod(third_week_of_1935) == 3
    @test subperiod(hundredth_day_of_year_54620) == 100
    @test subperiod(second_semester_of_2022) == 2
    @test_throws MethodError subperiod(undated_12)
end

@testset "frequency" begin
    @test frequency(year_2022) == Year(1)
    @test frequency(second_quarter_of_200) == Quarter(1)
    @test frequency(third_week_of_1935) == Week(1)
    @test frequency(hundredth_day_of_year_54620) == Day(1)
    @test frequency(second_semester_of_2022) == Semester(1)
    @test frequency(undated_12) === Int64(1)
end

# Range operations on dates
@testset "ranges" begin
    weeks = period(Week, 1932, 24):third_week_of_1935
    @test period(Week, 1932, 45) ∈ weeks
    @test period(Week, 1931, 45) ∉ weeks

    semesters = period(Semester, 2021, 2):second_semester_of_2022
    @test period(Semester, 2021, 2) ∈ semesters
    @test period(Semester, 2021, 1) ∉ semesters

    @test Undated(17) ∈ Undated(17):Undated(17)
    @test Undated(4) ∉ Undated(-4):Undated(2)
end

# Print/string/display/show
@testset "string" begin
    @test Dates.format(year_2022) == "2022"
    @test Dates.format(second_quarter_of_200) == "0200-Q2"
    @test Dates.format(third_week_of_1935) == "1935-W3"
    @test Dates.format(second_semester_of_2022) == "2022-S2"
    @test_throws MethodError Dates.format(undated_12)
    @test Dates.format(period(Month, 1729, 3)) == "1729-03"
    @test Dates.format(period(Month, 1729, 12)) == "1729-12"

    # Same issue as Dates.jl, it truncates on over-width.
    # See https://github.com/JuliaLang/julia/issues/46025
    @test_broken Dates.format(second_quarter_of_200) == "200-Q2"
    @test_broken Dates.format(hundredth_day_of_year_54620) == "54620-D100"
end
@testset "repr" begin
    @test endswith(repr(year_2022), "Year(2022)")
    @test endswith(repr(second_quarter_of_200), "Quarter(801)")
    @test endswith(repr(third_week_of_1935), "Week(100966)")
    @test endswith(repr(hundredth_day_of_year_54620), "Day(19949644)")
    @test endswith(repr(second_semester_of_2022), "Semester(4045)")
    @test repr(undated_12) == "12"
end

# Efficient (no overhead over Int64)
@testset "space" begin
    @test Base.summarysize(year_2022) <= sizeof(Int64)
    @test Base.summarysize(second_quarter_of_200) <= sizeof(Int64)
    @test Base.summarysize(third_week_of_1935) <= sizeof(Int64)
    @test Base.summarysize(hundredth_day_of_year_54620) <= sizeof(Int64)
    @test Base.summarysize(second_semester_of_2022) <= sizeof(Int64)
end

@testset "zeros" begin
    for P in subtypes(DatePeriod)
        p = period(P, 0, 1)
        @test Dates.value(p) == 0
        @test Date(p) == ExtendedDates.epoch(P)
    end
end

@testset "Basic parsing and formatting" begin
    @test Dates.format(parse(Week, "2012-W4")) == "2012-W4"
    @test_throws ArgumentError parse(Week, "2012-D4")
    @test Dates.format(parse(Day, "2012-D4")) == "2012-D4"
    @test Dates.format(parse(Quarter, "2012-Q4")) == "2012-Q4"
    @test Dates.format(parse(Month, "2012-04")) == "2012-04"
    @test_throws ArgumentError("Semester: 4 out of range (1:2)") parse(Semester, "2012-S4")
    @test Dates.format(parse(Semester, "2012-S2")) == "2012-S2"
    @test Dates.format(parse(Semester, "2012")) == "2012-S1"
    @test Dates.format(parse(Year, "2012")) == "2012"
end

@testset "Tricky parsing and formatting" begin
    # TODO
end

@testset "exhaustive constructor-accessor consistency" begin
    for (P, limit) in [
        (Day, 365),
        (Week, 52),
        (Month, 12),
        (Quarter, 4),
        (Semester, 2),
        (Year, 1)]
        for y in -10:10
            for s in 1:limit
                @test year(period(P, y, s)) == y
                @test subperiod(period(P, y, s)) == s
            end
        end
    end
end

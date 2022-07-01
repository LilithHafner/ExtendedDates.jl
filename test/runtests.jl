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

### Periods can be identified by (year, subperiod, frequency)

@testset "year" begin
    @test year(year_2022) == 2022
    @test year(second_quarter_of_200) == 200
    @test year(third_week_of_1935) == 1935
    @test year(hundredth_day_of_year_54620) == 54620
    @test year(second_semester_of_2022) == 2022
    @test_throws MethodError year(undated_12)
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
    @test_throws MethodError frequency(undated_12)
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
    @test string(year_2022) == "2022"
    @test string(second_quarter_of_200) == "200-Q2"
    @test string(third_week_of_1935) == "1935-W3"
    @test string(hundredth_day_of_year_54620) == "54620-D100"
    @test string(second_semester_of_2022) == "2022-S2"
    @test string(undated_12) == "Undated(12)"
end
@testset "repr" begin
    @test endswith(repr(year_2022), "UTInstant(Year(2022))")
    @test endswith(repr(second_quarter_of_200), "UTInstant(Quarter(801))")
    @test endswith(repr(third_week_of_1935), "UTInstant(Week(100965))")
    @test endswith(repr(hundredth_day_of_year_54620), "UTInstant(Day(19949644))")
    @test endswith(repr(second_semester_of_2022), "UTInstant(Semester(4045))")
    @test endswith(repr(undated_12), "Undated(12)")
end

# Efficient (no overhead over Int)
@testset "space" begin
    @test Base.summarysize(year_2022) <= sizeof(Int)
    @test Base.summarysize(second_quarter_of_200) <= sizeof(Int)
    @test Base.summarysize(third_week_of_1935) <= sizeof(Int)
    @test Base.summarysize(hundredth_day_of_year_54620) <= sizeof(Int)
    @test Base.summarysize(second_semester_of_2022) <= sizeof(Int)
end

@testset "zeros" begin
    for P in subtypes(DatePeriod)
        p = period(P, 0, 1)
        @test Dates.value(p) == 0
        @test Date(p) == ExtendedDates.epoch(P)
    end
end
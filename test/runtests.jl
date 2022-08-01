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
    @test Dates.format(hundredth_day_of_year_54620) == "54620-100"
    @test Dates.format(hundredth_day_of_year_54620 - Day(1)) == "54620-099"
    @test Dates.format(second_semester_of_2022) == "2022-S2"
    @test_throws MethodError Dates.format(undated_12)
    @test Dates.format(period(Month, 1729, 3)) == "1729-M03"
    @test Dates.format(period(Month, 1729, 12)) == "1729-M12"
end
@testset "repr" begin
    @test repr(year_2022) == "Year(2022)"
    @test repr(second_quarter_of_200) == "Quarter(798)"
    @test repr(third_week_of_1935) == "Week(100915)"
    @test repr(hundredth_day_of_year_54620) == "Day(19949279)"
    @test repr(second_semester_of_2022) == "Semester(4044)"
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

@testset "ones" begin
    for P in subtypes(DatePeriod)
        p = period(P, 1, 1)
        @test p == period(P, 1)
        @test Dates.value(p) == 1 == Dates.value(Date(p))
        @test Date(p) == ExtendedDates.epoch(P) == Date(1)
    end
end

@testset "day consistency" begin
    for date in Date(-2):Day(1):Date(5)
        year, month, day = yearmonthday(date)

        @test Dates.value(Date(year)) == Dates.value(period(Day, year))
        @test Dates.value(Date(year, 1, day)) == Dates.value(period(Day, year, day))
        @test Dates.value(Date(year, month, day)) == Dates.value(period(Day, year, month, day))
    end
end

@testset "Specific parsing and formatting" begin
    @test Dates.format(parse(Week, "2012-W4")) == "2012-W4"
    @test_throws ArgumentError parse(Week, "2012-D4")
    @test Dates.format(parse(Day, "2012-04")) == "2012-004"
    @test Dates.format(parse(Quarter, "2012-Q4")) == "2012-Q4"
    @test Dates.format(parse(Month, "2012-M04")) == "2012-M04"
    @test_throws ArgumentError("Semester: 4 out of range (1:2)") parse(Semester, "2012-S4")
    @test Dates.format(parse(Semester, "2012-S2")) == "2012-S2"
    @test Dates.format(parse(Semester, "2012")) == "2012-S1"
    @test Dates.format(parse(Year, "2012")) == "2012"
end

@testset "Generic parsing" begin
    @test parse(Period, "2022") == period(Year, 2022)
    @test parse(Period, "2022-S2") == period(Semester, 2022, 2)
    @test parse(Period, "2022-s2") == period(Semester, 2022,2)
    @test parse(Period, "2022-Q2") == period(Quarter, 2022, 2)
    @test parse(Period, "2022-q2") == period(Quarter, 2022,2)
    @test parse(Period, "2022-M2") == period(Month, 2022, 2)
    @test parse(Period, "2022-m2") == period(Month, 2022, 2)
    @test parse(Period, "2022-W2") == period(Week, 2022, 2)
    @test parse(Period, "2022-w2") == period(Week, 2022, 2)
    @test parse(Period, "2022-2-1") == period(Day, 2022, 2, 1)
    @test parse(Period, "2022-02-1") == period(Day, 2022, 2, 1)
    @test parse(Period, "2022-2-01") == period(Day, 2022, 2, 1)
    @test parse(Period, "2022-02-01") == period(Day, 2022, 2, 1)
end

@testset "Ordinal dates" begin
    # https://en.wikipedia.org/wiki/ISO_8601#Ordinal_dates
    @test parse(Period, "2022-002") == period(Day, 2022, 2)
    @test parse(Period, "2022-17") == period(Day, 2022, 17)
    @test parse(Period, "2022-360") == period(Day, 2022, 360)

    # nonstandard, but they still parse
    @test parse(Period, "2022-D002") == period(Day, 2022, 2)
    @test parse(Period, "2022-d002") == period(Day, 2022, 2)
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

@testset "Semesters" begin
    @test string(Semester(4)) == "4 semesters"
    @test string(Year(1)+Semester(1)) == "1 year, 1 semester"
    @test_broken string(Year(1)+Semester(1)+Week(1)) == "1 year, 1 semester, 1 week"
    @test string(Year(1)+Semester(1)+Week(1)) == "1 year, 1 week, 1 semester"

    @test Semester(3) < Semester(5)
    @test Semester(4) >= Semester(4)
    @test Semester(4) != Semester(5)
    @test Semester(4) == Semester(4)
    @test Semester("64") == Semester(64) == Quarter(128)
    @test Semester(2) == Year(1)
    @test Semester(3) != Year(1)
    @test Semester(2) != Day(365)
    @test Semester(2) != Day(366)
    @test Semester(0) == Day(0)

    @test allunique(hash.(vcat(Semester(-100):Semester(100), Week(-100):Week(-1), Week(1):Week(100))))
    @test hash(Week(0)) == hash(Semester(0))
    @test hash(Quarter(4)) == hash(Semester(2)) == hash(Year(1))

    for x in [-300, -3, 1, 2, 3, 300, 10^10]
        for P in [Nanosecond, Microsecond, Millisecond, Second, Minute, Hour, Day, Week, Month, Quarter]
            @test Dates.periodisless(P(x), Semester(2))
        end
        @test Dates.periodisless(Semester(2), Year(x))
        @test Dates.periodisless(Semester(2), Semester(x)) == (2 < x)
    end

    @test Dates.toms(Semester(1729)) == Dates.toms(Month(6*1729))
    @test Dates.days(Semester(1729)) == Dates.days(Month(6*1729))

    @test_broken Dates.semester(1) == 1 # this is easy to fix with eval, but probably a bad idea.
    for f in (identity, DateTime, x -> DateTime(x) + Hour(3))
        for (i, day) in enumerate(Date(1312):Day(1):Date(1312, 6, 30))
            d = f(day)
            @test ExtendedDates.semester(d) == semesterofyear(d) == 1
            @test trunc(d, Semester) == floor(d, Semester) == firstdayofsemester(d) == Date(1312)
            @test lastdayofsemester(d) == Date(1312, 6, 30)
            @test dayofsemester(d) == i
            @test dayofsemester(d) == i
            @test ceil(d, Semester) >= d
            @test ceil(d, Semester) < d + Semester(1)
            @test trunc(ceil(d, Semester), Semester) == ceil(d, Semester)
        end
        for (i, day) in enumerate(Date(1312, 7):Day(1):Date(1312, 12, 31))
            d = f(day)
            @test ExtendedDates.semester(d) == semesterofyear(d) == 2
            @test trunc(d, Semester) == floor(d, Semester) == firstdayofsemester(d) == Date(1312, 7)
            @test lastdayofsemester(d) == Date(1312, 12, 31)
            @test dayofsemester(d) == i
            @test ceil(d, Semester) >= d
            @test ceil(d, Semester) < d + Semester(1)
            @test trunc(ceil(d, Semester), Semester) == ceil(d, Semester)
        end
    end

    for t in (today(), now())
        @test t + Month(7) - Semester(1) == t + Month(1)
        @test Semester(2) + t == t + Year(1)
    end
end

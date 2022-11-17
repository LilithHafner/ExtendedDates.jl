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
    @test Year(1) === frequency(year_2022) === frequency(typeof(year_2022))
    @test Quarter(1) === frequency(second_quarter_of_200) === frequency(typeof(second_quarter_of_200))
    @test Week(1) === frequency(third_week_of_1935) === frequency(typeof(third_week_of_1935))
    @test Day(1) === frequency(hundredth_day_of_year_54620) === frequency(typeof(hundredth_day_of_year_54620))
    @test Semester(1) === frequency(second_semester_of_2022) === frequency(typeof(second_semester_of_2022))
    @test Int64(1) === frequency(undated_12) === frequency(typeof(undated_12))
end

@testset "one" begin
    @test one(year_2022) === one(second_quarter_of_200) === one(third_week_of_1935) ===
          one(hundredth_day_of_year_54620) === one(second_semester_of_2022) ===
          one(undated_12) === 1
end

@testset "oneunit" begin
    @test oneunit(year_2022) === period(Year, 1, 1)
    @test oneunit(second_quarter_of_200) === period(Quarter, 1, 1)
    @test oneunit(third_week_of_1935) === period(Week, 1, 1)
    @test oneunit(hundredth_day_of_year_54620) === period(Day, 1, 1)
    @test oneunit(second_semester_of_2022) === period(Semester, 1, 1)
    @test oneunit(undated_12) === 1

    @test typeof(oneunit(year_2022)) === typeof(year_2022)
    @test typeof(oneunit(second_quarter_of_200)) === typeof(second_quarter_of_200)
    @test typeof(oneunit(third_week_of_1935)) === typeof(third_week_of_1935)
    @test typeof(oneunit(hundredth_day_of_year_54620)) === typeof(hundredth_day_of_year_54620)
    @test typeof(oneunit(second_semester_of_2022)) === typeof(second_semester_of_2022)
    @test typeof(oneunit(undated_12)) == typeof(undated_12)
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
    @test string(second_quarter_of_200) == "0200-Q2"
    @test string(third_week_of_1935) == "1935-W3"
    @test string(hundredth_day_of_year_54620) == "54620-04-09"
    @test string(second_semester_of_2022) == "2022-S2"
    @test string(undated_12) == "12"
    @test string(period(Month, 1729, 3)) == "1729-M03"
    @test string(period(Month, 1729, 12)) == "1729-M12"
end
@testset "format" begin
    @test Dates.format(year_2022) == "2022"
    @test Dates.format(second_quarter_of_200) == "0200-Q2"
    @test Dates.format(third_week_of_1935) == "1935-W3"
    @test Dates.format(hundredth_day_of_year_54620) == "54620-04-09"
    @test Dates.format(second_semester_of_2022) == "2022-S2"
    @test_throws MethodError Dates.format(undated_12)
    @test Dates.format(period(Month, 1729, 3)) == "1729-M03"
    @test Dates.format(period(Month, 1729, 12)) == "1729-M12"
end
@testset "repr" begin
    @test repr(year_2022) == "YearSE(\"2022\")"
    @test repr(second_quarter_of_200) == "QuarterSE(\"0200-Q2\")"
    @test repr(third_week_of_1935) == "WeekSE(\"1935-W3\")"
    @test repr(hundredth_day_of_year_54620) == "DaySE(\"54620-04-09\")"
    @test repr(second_semester_of_2022) == "SemesterSE(\"2022-S2\")"
    @test repr(undated_12) == "12"

    @test year_2022 === eval(Meta.parse(repr(year_2022)))
    @test second_quarter_of_200 === eval(Meta.parse(repr(second_quarter_of_200)))
    @test third_week_of_1935 === eval(Meta.parse(repr(third_week_of_1935)))
    @test hundredth_day_of_year_54620 === eval(Meta.parse(repr(hundredth_day_of_year_54620)))
    @test second_semester_of_2022 === eval(Meta.parse(repr(second_semester_of_2022)))
    @test undated_12 === eval(Meta.parse(repr(undated_12)))
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
        @test Date(p) == ExtendedDates.EPOCH == Date(1)
    end
end

@testset "Specific parsing and formatting" begin
    @test Dates.format(parse(WeekSE, "2012-W4")) == "2012-W4"
    @test_throws ArgumentError parse(WeekSE, "2012-D4")
    @test Dates.format(parse(DaySE, "2012-04-13")) == "2012-04-13"
    @test Dates.format(parse(DaySE, "2012-04")) == "2012-04-01"
    @test Dates.format(parse(QuarterSE, "2012-Q4")) == "2012-Q4"
    @test Dates.format(parse(MonthSE, "2012-M04")) == "2012-M04"
    @test_throws ArgumentError("Semester: 4 out of range (1:2)") parse(SemesterSE, "2012-S4")
    @test Dates.format(parse(SemesterSE, "2012-S2")) == "2012-S2"
    @test Dates.format(parse(SemesterSE, "2012")) == "2012-S1"
    @test Dates.format(parse(YearSE, "2012")) == "2012"
end

@testset "Generic parsing" begin
    @test parse(PeriodSE, "2022") == period(Year, 2022)
    @test parse(PeriodSE, "2022-S2") == period(Semester, 2022, 2)
    @test parse(PeriodSE, "2022-s2") == period(Semester, 2022,2)
    @test parse(PeriodSE, "2022-Q2") == period(Quarter, 2022, 2)
    @test parse(PeriodSE, "2022-q2") == period(Quarter, 2022,2)
    @test parse(PeriodSE, "2022-M2") == period(Month, 2022, 2)
    @test parse(PeriodSE, "2022-m2") == period(Month, 2022, 2)
    @test parse(PeriodSE, "2022-W2") == period(Week, 2022, 2)
    @test parse(PeriodSE, "2022-w2") == period(Week, 2022, 2)
    @test parse(PeriodSE, "2022-2-1") == period(Day, 2022, 2, 1)
    @test parse(PeriodSE, "2022-02-1") == period(Day, 2022, 2, 1)
    @test parse(PeriodSE, "2022-2-01") == period(Day, 2022, 2, 1)
    @test parse(PeriodSE, "2022-02-01") == period(Day, 2022, 2, 1)
end

@testset "Ordinal dates" begin
    # https://en.wikipedia.org/wiki/ISO_8601#Ordinal_dates
    @test parse(PeriodSE, "2022-002") == period(Day, 2022, 2)
    @test parse(PeriodSE, "2022-17") == period(Day, 2022, 17)
    @test parse(PeriodSE, "2022-360") == period(Day, 2022, 360)

    # nonstandard, but they still parse
    @test parse(PeriodSE, "2022-D002") == period(Day, 2022, 2)
    @test parse(PeriodSE, "2022-d002") == period(Day, 2022, 2)
end

@testset "Bulk parsing" begin
    @test parse(Tuple{PeriodSE, DateFormat}, "2022-S2") == (period(Semester, 2022, 2), Dates.default_format(SemesterSE))
    p, df = parse(Tuple{PeriodSE, DateFormat}, "2022-s2")
    @test p == period(Semester, 2022,2)
    @test df.tokens == (dateformat"YYYY-\sP").tokens # TODO revise pending #47541
    @test parse_periods(["1930", "1940", "1950"]) == period.(Year, [1930, 1940, 1950])
    @test parse(Vector{<:PeriodSE}, ["123-7-2", "123-8-2", "124-2-4"]) == [
        period(Day, 123, 7, 2),
        period(Day, 123, 8, 2),
        period(Day, 124, 2, 4)
    ]
end

@testset "Short name parsing" begin
    @test MonthSE("2022-M4") == PeriodSE("2022-M4") == period(Month, 2022, 4)
end

@testset "Custom formatting" begin
    @test Dates.format(period(Year, 2022), dateformat"YYYY") == "2022"
    @test Dates.format(period(Quarter, 2022, 2), dateformat"Q\uart\er #P of th\e \y\ear yy") == "Quarter #2 of the year 22"
    @test Dates.format(period(Week, 2022, 50), "W\\e\\ek #P of th\\e \\y\\ear YYYYYY") == "Week #50 of the year 002022"
end

@testset "day consistency" begin
    for date in Date(-2):Day(1):Date(5)
        year, month, day = yearmonthday(date)

        @test Dates.value(Date(year)) == Dates.value(period(Day, year))
        @test Dates.value(Date(year, 1, day)) == Dates.value(period(Day, year, day))
        @test Dates.value(Date(year, month, day)) == Dates.value(period(Day, year, month, day))
    end

    @test parse(Date, "2012-7-14") == Date(parse(DaySE, "2012-7-14"))
    Dates.format(parse(DaySE, "2012-7-4")) == "2012-07-04"
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
    if VERSION < v"1.9.0-DEV.1160"
        @test_broken string(Year(1)+Semester(1)+Week(1)) == "1 year, 1 semester, 1 week"
        @test string(Year(1)+Semester(1)+Week(1)) == "1 year, 1 week, 1 semester"
    else
        @test string(Year(1)+Semester(1)+Week(1)) == "1 year, 1 semester, 1 week"
        @test string(Year(1)+Week(1)+Semester(1)) == "1 year, 1 semester, 1 week"
        @test string(Semester(1)+Year(1)+Week(1)) == "1 year, 1 semester, 1 week"
    end

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

    @test allunique(hash.(vcat(SemesterSE(-100, 1):SemesterSE(100, 1), WeekSE(-100, 1):WeekSE(-1, 1), WeekSE(1, 1):WeekSE(100, 1))))
    @test hash(Week(0)) == hash(Semester(0))
    @test hash(Quarter(4)) == hash(Semester(2)) == hash(Year(1))

    if VERSION < v"1.9.0-DEV.1160"
        for x in [-300, -3, 1, 2, 3, 300, 10^10]
            for P in [Nanosecond, Microsecond, Millisecond, Second, Minute, Hour, Day, Week, Month, Quarter]
                @test Dates.periodisless(P(x), Semester(2))
            end
            @test Dates.periodisless(Semester(2), Year(x))
            @test Dates.periodisless(Semester(2), Semester(x)) == (2 < x)
        end
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

    @test convert(Month, Semester(1)) === Month(6)
    @test convert(Year, Semester(2)) === Year(1)
    @test convert(Quarter, Semester(2)) === Quarter(4)

    @test promote_rule(Quarter, Semester) === promote_rule(Quarter, Year) === Union{}
    @test promote_rule(Semester, Quarter) === promote_rule(Year, Quarter) === Quarter
    @test promote_rule(Year, Semester) === Semester !== promote_rule(Year, Month) === Month
    @test promote_rule(Semester, Year) === promote_rule(Month, Year) === Union{}

    @test Quarter(Date("2022-01-12")) === Quarter(1)
    @test Semester(Date("2022-11-12")) === Semester(2)
    @test Semester(Date("2022-01-12")) === Semester(1)
    @test Semester(DateTime("2022-11-12T19:15:02.015")) === Semester(2)
    @test Semester(DateTime("2022-01-12T19:15:02.015")) === Semester(1)

    @test string(Semester(1)) == "1 semester"
    @test string(Semester(1729)) == "1729 semesters"
    @test string(Semester.(1:4)) == "[Semester(1), Semester(2), Semester(3), Semester(4)]"
    @test string(Quarter(1)) == "1 quarter"
    @test string(Quarter(1729)) == "1729 quarters"
    @test string(Quarter.(1:4)) == "[Quarter(1), Quarter(2), Quarter(3), Quarter(4)]"
end

@testset "short constructors" begin
    @test SemesterSE(1930, 1) === period(Semester, 1930, 1)
    @test QuarterSE(1931, 4) === period(Quarter, 1931, 4)
    @test MonthSE(1932, 3) === period(Month, 1932, 3)
    @test WeekSE(1933, 50) === period(Week, 1933, 50)
    @test DaySE(1934, 12, 31) === period(Day, 1934, 12, 31)
end

@testset "show(::MIME\"text/plain\")" begin
    buf = IOBuffer()
    @test show(buf, MIME"text/plain"(), DaySE(1952, 4, 17)) === nothing
    @test show(buf, MIME"text/plain"(), WeekSE(1952, 45)) === nothing
    @test String(take!(buf)) == "1952-04-17" * "1952-W45"
end

@testset "ordering and equality" begin
    periods = [period.(Month, 2020, 1:5); period.(Quarter, 2020, 1:3); period.(Year, 2019:2021)]
    @test !issorted(periods)
    sort!(periods)
    @test issorted(periods)
    @test periods == parse.(PeriodSE, ["2019", "2020-M01", "2020-Q1", "2020", "2020-M02", "2020-M03", "2020-M04", "2020-Q2", "2020-M05", "2020-Q3", "2021"])
    tperiods = reshape(periods, 1, length(periods))

    @test (periods .=== tperiods) == Bool[
        1  0  0  0  0  0  0  0  0  0  0
        0  1  0  0  0  0  0  0  0  0  0
        0  0  1  0  0  0  0  0  0  0  0
        0  0  0  1  0  0  0  0  0  0  0
        0  0  0  0  1  0  0  0  0  0  0
        0  0  0  0  0  1  0  0  0  0  0
        0  0  0  0  0  0  1  0  0  0  0
        0  0  0  0  0  0  0  1  0  0  0
        0  0  0  0  0  0  0  0  1  0  0
        0  0  0  0  0  0  0  0  0  1  0
        0  0  0  0  0  0  0  0  0  0  1
    ]

    @test (periods .== tperiods) == Bool[
        1  0  0  0  0  0  0  0  0  0  0
        0  1  1  1  0  0  0  0  0  0  0
        0  1  1  1  0  0  0  0  0  0  0
        0  1  1  1  0  0  0  0  0  0  0
        0  0  0  0  1  0  0  0  0  0  0
        0  0  0  0  0  1  0  0  0  0  0
        0  0  0  0  0  0  1  1  0  0  0
        0  0  0  0  0  0  1  1  0  0  0
        0  0  0  0  0  0  0  0  1  0  0
        0  0  0  0  0  0  0  0  0  1  0
        0  0  0  0  0  0  0  0  0  0  1
    ]

    @test (isless.(periods, tperiods)) == Bool[
        0  1  1  1  1  1  1  1  1  1  1
        0  0  0  0  1  1  1  1  1  1  1
        0  0  0  0  1  1  1  1  1  1  1
        0  0  0  0  1  1  1  1  1  1  1
        0  0  0  0  0  1  1  1  1  1  1
        0  0  0  0  0  0  1  1  1  1  1
        0  0  0  0  0  0  0  0  1  1  1
        0  0  0  0  0  0  0  0  1  1  1
        0  0  0  0  0  0  0  0  0  1  1
        0  0  0  0  0  0  0  0  0  0  1
        0  0  0  0  0  0  0  0  0  0  0
    ]

    @test all((periods .== tperiods) .⊻ isless.(periods, tperiods) .⊻ isless.(tperiods, periods))

    @test (periods .< tperiods) == Bool[
        0  1  1  1  1  1  1  1  1  1  1
        0  0  0  0  1  1  1  1  1  1  1
        0  0  0  0  0  0  1  1  1  1  1
        0  0  0  0  0  0  0  0  0  0  1
        0  0  0  0  0  1  1  1  1  1  1
        0  0  0  0  0  0  1  1  1  1  1
        0  0  0  0  0  0  0  0  1  1  1
        0  0  0  0  0  0  0  0  0  1  1
        0  0  0  0  0  0  0  0  0  1  1
        0  0  0  0  0  0  0  0  0  0  1
        0  0  0  0  0  0  0  0  0  0  0
    ] == (tperiods .> periods) == (!).(periods .>= tperiods) == (!).(tperiods .<= periods)

    @test period(Day, 2000, 1) < period(Week, 2000, 1)
    @test period(Day, 2000, 1) != period(Week, 2000, 1)

    @test period(Day, 2001, 1) < period(Week, 2001, 2)
    @test period(Day, 2001, 1) == period(Week, 2001, 1)
    @test !(period(Day, 2001, 1) < period(Week, 2001, 1))
end
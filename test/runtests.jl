using Test
using KanjiCoverage

@testset "kanji detection" begin
    @test is_kanji('日')
    @test is_kanji('𠀀')
    @test !is_kanji('A')
end

@testset "kanji analysis" begin
    levels = Dict("日" => "N5", "学" => "N5", "語" => "N2")
    result = analyze("日本語 学A", levels)

    @test result["N5"] == 2
    @test result["N2"] == 1
    @test result["unknown count"] == 1
    @test result["unknown kanji"] == "本"
    @test result["N5 percent"] == 50.0
    @test result["comfort level"] == "N2"
    @test result["working level"] == "unknown"
    @test result["mastery level"] == "unknown"
end

@testset "empty analysis" begin
    result = analyze("no kanji", Dict{String, String}())
    @test sum(result["N1 percent"] for _ in 1:1) == 0.0
    @test result["unknown count"] == 0
    @test result["comfort level"] == ""
end

@testset "summaries" begin
    results = [
        Dict{String, Any}(
            "file" => "ff_ao3.txt",
            "comfort level" => "N5",
            "working level" => "N2",
            "mastery level" => "unknown",
        ),
        Dict{String, Any}(
            "file" => "nhk_news_easy.txt",
            "comfort level" => "N3",
            "working level" => "N1",
            "mastery level" => "N1",
        ),
    ]

    summary = summarize(results, ["all", "ff"])
    @test length(summary) == 6
    @test only(filter(row -> row["tag"] == "ff" && row["category"] == "comfort", summary))["N5"] == 1
    @test only(filter(row -> row["tag"] == "ff" && row["category"] == "comfort", summary))["N5 percent"] == 100.0
end

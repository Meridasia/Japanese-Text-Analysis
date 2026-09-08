using JSON
using Plots
const LEVELS = ["N5", "N4", "N3", "N2", "N1", "unknown"]
const TAGS = ["all", "ff", "nhk_news_easy", "nhk_news_normal"]
const KANJI_DIR = joinpath(@__DIR__, "data", "json", "kanji")
const INPUT_DIR = joinpath(@__DIR__, "input")
const OUTPUT_DIR = joinpath(@__DIR__, "output")
const RESULTS_FILE = joinpath(OUTPUT_DIR, "results.json")

function load_kanji_levels(directory)
    levels = Dict{String, String}()
    for file in readdir(directory; join=true), entry in JSON.parsefile(file)
        levels[entry["character"]] = entry["level"]
    end
    levels
end

is_kanji(c::Char) =
    c in ('\u3400':'\u4dbf') ||
    c in ('\u4e00':'\u9fff') ||
    c in ('\uf900':'\ufaff') ||
    c in ('\U00020000':'\U0002a6df')

function analyze(text, kanji_levels)
    counts = Dict(level => 0 for level in LEVELS)
    unknown = Set{Char}()
    for character in text
        is_kanji(character) || continue
        level = get(kanji_levels, string(character), "unknown")
        counts[level] += 1
        level == "unknown" && push!(unknown, character)
    end

    total = sum(values(counts))
    percentages = Dict(level => total == 0 ? 0.0 : round(counts[level] / total * 100, digits=2) # ? means then; : means else; if total 0 then % 0 else calculate %
                       for level in LEVELS)
    cumulative = 0.0
    threshold_levels = Dict(75 => "", 85 => "", 95 => "")
    for level in LEVELS
        cumulative += percentages[level]
        for threshold in keys(threshold_levels)
            cumulative >= threshold && threshold_levels[threshold] == "" &&
                (threshold_levels[threshold] = level)
        end
    end

    result = Dict{String, Any}(
        "N1" => counts["N1"], "N2" => counts["N2"], "N3" => counts["N3"],
        "N4" => counts["N4"], "N5" => counts["N5"],
        "N1 percent" => percentages["N1"], "N2 percent" => percentages["N2"],
        "N3 percent" => percentages["N3"], "N4 percent" => percentages["N4"],
        "N5 percent" => percentages["N5"], "unknown count" => counts["unknown"],
        "unknown percent" => percentages["unknown"],
        "unknown kanji" => join(sort!(collect(unknown)), ", "),
        "comfort level" => threshold_levels[75],
        "working level" => threshold_levels[85],
        "mastery level" => threshold_levels[95],
    )
    println("N1-N5: ", [counts[level] for level in reverse(LEVELS[1:5])])
    println("Unbekannt: ", counts["unknown"], " (", percentages["unknown"], "%)")
    println("Unbekannte Kanji: ", result["unknown kanji"])
    println("Gesamtanzahl der Kanji: ", total)
    println("Komfortlevel: ", result["comfort level"])
    println("Arbeitslevel: ", result["working level"])
    println("Meisterschaftlevel: ", result["mastery level"])
    result
end

function summarize(results, tags)
    summary = Dict(category => Dict(level => 0 for level in LEVELS)
                   for category in ("comfort", "working", "mastery"))
    for result in results
        for (category, key) in (("comfort", "comfort level"),
                                ("working", "working level"),
                                ("mastery", "mastery level"))
            summary[category][result[key]] += 1
        end
    end

    total_results = length(results)
    [Dict("category" => category,
          "tag" => "total",
          (level => summary[category][level] for level in LEVELS)...,
          ("$(level) percent" => total_results == 0 ? 0.0 :
              round(summary[category][level] / total_results * 100, digits=2)
           for level in LEVELS)...)
     for category in ("comfort", "working", "mastery")]
end

function summarize2(results, tags)
    tags = tags isa AbstractString ? [tags] : collect(tags)

    isempty(tags) && (tags = ["all"])

    summary = Dict(
        tag => Dict(
            category => Dict(level => 0 for level in LEVELS)
            for category in ("comfort", "working", "mastery")
        )
        for tag in tags
    )

    for result in results
        for tag in tags
            if tag == "all" || occursin(tag, result["file"])
                for (category, key) in (
                    ("comfort", "comfort level"),
                    ("working", "working level"),
                    ("mastery", "mastery level")
                )
                    summary[tag][category][result[key]] += 1
                end
            end
        end
    end

    [
        Dict(
            "category" => category,
            "tag" => tag,
            (level => summary[tag][category][level] for level in LEVELS)...,
            ("$(level) percent" =>
                total_results == 0 ? 0.0 :
                round(summary[tag][category][level] / total_results * 100, digits=2)
             for level in LEVELS)...
        )
        for tag in tags
        for category in ("comfort", "working", "mastery")
        for total_results in [sum(values(summary[tag][category]))]
    ]
end

mkpath(OUTPUT_DIR)
results = isfile(RESULTS_FILE) ? JSON.parsefile(RESULTS_FILE) : Any[]
known_files = Set(result["file"] for result in results)
kanji_levels = load_kanji_levels(KANJI_DIR)

for file in sort(readdir(INPUT_DIR; join=true))
    filename = basename(file)
    if filename in known_files
        println("Datei ", filename, " wurde bereits analysiert. Überspringe...")
        continue
    end
    println("\nDatei ", filename, ":")
    result = analyze(read(file, String), kanji_levels)
    result["file"] = filename
    push!(results, result)
end

open(RESULTS_FILE, "w") do file
    JSON.print(file, results, 2)
end

open(joinpath(OUTPUT_DIR, "total.json"), "w") do file
    JSON.print(file, summarize2(results, TAGS), 2)
end

function plot_total(data_file, output_file)
    data = JSON.parsefile(data_file)
    categories = ("comfort", "working", "mastery")
    x_labels = LEVELS
    tag_data = Dict(
        category => Dict(
            record["tag"] => [record["$(level) percent"] for level in x_labels]
            for record in data if record["category"] == category
        )
        for category in categories
    )

    graphs = map(categories) do category
        tags = sort!(collect(keys(tag_data[category])))
        isempty(tags) && error("No data found for category: $category")

        graph = plot(
            x_labels,
            tag_data[category][tags[1]];
            title = titlecase(category),
            xlabel = "JLPT level",
            ylabel = "Percentage",
            ylims = (0, 100),
            label = tags[1],
            marker = :circle
        )
        for tag in tags[2:end]
            plot!(graph, x_labels, tag_data[category][tag]; label = tag, marker = :circle)
        end
        graph
    end

    comparison = plot(graphs...; layout = (1, 3), size = (1500, 500), link = :y)
    savefig(comparison, output_file)
    comparison
end

plot_total(joinpath(OUTPUT_DIR, "total.json"), joinpath(OUTPUT_DIR, "comparison.png"))
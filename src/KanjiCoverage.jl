module KanjiCoverage

using JSON
using Plots

export LEVELS, TAGS, is_kanji, load_kanji_levels, analyze, summarize,
    run_analysis, plot_total

const LEVELS = ["N5", "N4", "N3", "N2", "N1", "unknown"]
const TAGS = ["all", "ff", "news"] # declare own tags here

"""Load a character-to-level lookup table from all JSON files in `directory`."""
function load_kanji_levels(directory::AbstractString)
    levels = Dict{String, String}()
    for file in readdir(directory; join=true)
        for entry in JSON.parsefile(file)
            levels[entry["character"]] = entry["level"]
        end
    end
    levels
end

"""Return whether `character` belongs to one of the common CJK ideograph blocks."""
is_kanji(character::Char) =
    character in ('\u3400':'\u4dbf') || #CJK Unified Ideographs Extension A
    character in ('\u4e00':'\u9fff') || #CJK Unified Ideographs
    character in ('\uf900':'\ufaff') || #CJK Compatibility Ideographs
    character in ('\U00020000':'\U0002a6df') #CJK Unified Ideographs Extension B
    # further extensions exist, but are rarely used in modern Japanese

"""Analyze kanji coverage in `text` using a character-to-level lookup table."""
function analyze(text::AbstractString, kanji_levels::AbstractDict)
    counts = Dict(level => 0 for level in LEVELS)  # {"N5"=>0, "N4"=>0, ..., "unknown"=>0}
    unknown = Set{Char}()

    for character in text
        is_kanji(character) || continue   # skip non-kanji characters
        level = get(kanji_levels, string(character), "unknown")
        counts[level] += 1
        level == "unknown" && push!(unknown, character)
    end

    total = sum(values(counts))
    percentages = Dict(
        level => total == 0 ? 0.0 : round(counts[level] / total * 100, digits=2)
        for level in LEVELS
    )

    cumulative = 0.0
    threshold_levels = Dict(75 => "", 85 => "", 95 => "")
    for level in LEVELS
        cumulative += percentages[level]
        for threshold in keys(threshold_levels)
            cumulative >= threshold && threshold_levels[threshold] == "" &&
                (threshold_levels[threshold] = level)
        end
    end

    Dict{String, Any}(
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
end


"""Summarize level distributions separately for each filename tag."""
function summarize(results, tags=TAGS)
    selected_tags = tags isa AbstractString ? [tags] : collect(tags)
    isempty(selected_tags) && (selected_tags = ["all"])

    summary = Dict(
        tag => Dict(
            category => Dict(level => 0 for level in LEVELS)
            for category in ("comfort", "working", "mastery")
        )
        for tag in selected_tags
    )

    for result in results
        for tag in selected_tags
            if tag == "all" || occursin(tag, result["file"])
                for (category, key) in (
                    ("comfort", "comfort level"),
                    ("working", "working level"),
                    ("mastery", "mastery level"),
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
            ("$(level) percent" => total_results == 0 ? 0.0 :
                round(summary[tag][category][level] / total_results * 100, digits=2)
             for level in LEVELS)...,
        )
        for tag in selected_tags
        for category in ("comfort", "working", "mastery")
        for total_results in [sum(values(summary[tag][category]))]
    ]
end

"""Analyze new input files and write results and summaries below `output_dir`."""
function run_analysis(
    input_dir::AbstractString,
    kanji_dir::AbstractString,
    output_dir::AbstractString;
    tags=TAGS,
)
    mkpath(output_dir)
    results_file = joinpath(output_dir, "results.json")
    results = isfile(results_file) ? JSON.parsefile(results_file) : Any[]
    known_files = Set(result["file"] for result in results)
    kanji_levels = load_kanji_levels(kanji_dir)

    for file in sort(readdir(input_dir; join=true))
        filename = basename(file)
        filename in known_files && continue
        result = analyze(read(file, String), kanji_levels)
        result["file"] = filename
        push!(results, result)
    end

    open(results_file, "w") do file
        JSON.print(file, results, 2)
    end
    open(joinpath(output_dir, "total.json"), "w") do file
        JSON.print(file, summarize(results, tags), 2)
    end
    results
end

"""Create a three-panel comparison plot from a `summarize` JSON file."""
function plot_total(data_file::AbstractString, output_file::AbstractString)
    data = JSON.parsefile(data_file)
    categories = ("comfort", "working", "mastery")
    tag_data = Dict(
        category => Dict(
            record["tag"] => [record["$(level) percent"] for level in LEVELS]
            for record in data if record["category"] == category
        )
        for category in categories
    )

    graphs = map(categories) do category
        tags = sort!(collect(keys(tag_data[category])))
        isempty(tags) && error("No data found for category: $category")
        graph = plot(
            LEVELS,
            tag_data[category][tags[1]];
            title=titlecase(category),
            xlabel="JLPT level",
            ylabel="Percentage",
            ylims=(0, 100),
            label=tags[1],
            marker=:circle,
        )
        for tag in tags[2:end]
            plot!(graph, LEVELS, tag_data[category][tag]; label=tag, marker=:circle)
        end
        graph
    end

    comparison = plot(graphs...; layout=(1, 3), size=(1500, 500), link=:y)
    savefig(comparison, output_file)
    comparison
end

end

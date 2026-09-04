using Pkg
Pkg.add("JSON")
using JSON
path = joinpath(@__DIR__, "data", "json", "kanji", "n5.json")
data = JSON.parsefile(path) # liest die JSON-Datei und gibt ein Array von Dictionaries zurück

println(data[1])   # first entry
println(keys(data[1]))  # field names
println(data[1]["character"])  # first kanji character
println(data[1]["level"])  # level of the first kanji character

using JSON

base_dir = joinpath(@__DIR__, "data", "json", "kanji")

function load_kanji_level(directory::String)
    kanji_levels = Dict{String, String}()

    for file in readdir(directory; join=true)
        data = JSON.parsefile(file)

        for entry in data
            kanji_levels[entry["character"]] = entry["level"]
        end
    end

    return kanji_levels
end

kanji_levels = load_kanji_level(base_dir)
is_kanji(c::Char) =
    c in ('\u3400':'\u4dbf') ||
    c in ('\u4e00':'\u9fff') ||
    c in ('\uf900':'\ufaff') ||
    c in ('\U00020000':'\U0002a6df')

get(kanji_levels, "一", "unbekannt")
is_kanji('一')  # true

# read text files from input directory
input_dir = joinpath(@__DIR__, "input")
text = String[]
name = String[]
output_dir = joinpath(@__DIR__, "output")
if !isdir(output_dir)
    mkpath(output_dir)
end
if !isfile(joinpath(output_dir, "results.json"))
    results = []
else
    results = JSON.parsefile(
        joinpath(output_dir, "results.json")
    )
end
unknown_kanji = Set{Char}()
for file in sort(readdir(input_dir; join=true))
    push!(text, read(file, String))
    push!(name, splitext(basename(file))[1])
end

for i in 1:length(text)
counts = Dict(
    "N1" => 0,
    "N2" => 0,
    "N3" => 0,
    "N4" => 0,
    "N5" => 0,
    "unknown" => 0,
)
counts_percent = []
unknown_kanji = Set{Char}()
    for j in text[i]
        if is_kanji(j)
            level = get(kanji_levels, string(j), "");
            if level !== ""
                counts[level] += 1
            else
                counts["unknown"] += 1
                if !in(j, unknown_kanji)
                    push!(unknown_kanji, j)
                end
            end

        end
    end
total = sum(values(counts))
levels = ["N1", "N2", "N3", "N4", "N5", "unknown"]
for level in levels
    push!(counts_percent, round(counts[level] / total * 100, digits=2))
end

    println("\nDatei ", name[i], ":")
    println("N1: ", counts["N1"], " (", counts_percent[1], "%)")
    println("N2: ", counts["N2"], " (", counts_percent[2], "%)")
    println("N3: ", counts["N3"], " (", counts_percent[3], "%)")
    println("N4: ", counts["N4"], " (", counts_percent[4], "%)")
    println("N5: ", counts["N5"], " (", counts_percent[5], "%)")
    println("Unbekannt: ", counts["unknown"], " (", counts_percent[6], "%)")
    println("Unbekannte Kanji: ", join(collect(unknown_kanji), ", "))
    println("Gesamtanzahl der Kanji: ", total)
    
    results_entry = Dict(
        "file" => name[i],
        "N1" => counts["N1"],
        "N2" => counts["N2"],
        "N3" => counts["N3"],
        "N4" => counts["N4"],
        "N5" => counts["N5"],
        "N1 percent" => counts_percent[1],
        "N2 percent" => counts_percent[2],
        "N3 percent" => counts_percent[3],
        "N4 percent" => counts_percent[4],
        "N5 percent" => counts_percent[5],
        "unknown count" => counts["unknown"],
        "unknown percent" => counts_percent[6],
        "unknown kanji" => join(collect(unknown_kanji), ", "),
    )
    push!(results, results_entry)
end

open(joinpath(output_dir, "results.json"), "w") do file
    JSON.print(file, results, 2)
end
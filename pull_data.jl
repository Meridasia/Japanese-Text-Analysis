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


 get(kanji_levels, "一", "unbekannt")

# read text files from input directory
input_dir = joinpath(@__DIR__, "input")
text = String[]
name = String[]
results = []
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
    "N5" => 0
)
    for j in text[i]
        level = get(kanji_levels, string(j), "");
        if level !== ""
            counts[level] += 1
        end
    end
    println("\nDatei ", name[i], ":")
    println("N1: ", counts["N1"])
    println("N2: ", counts["N2"])
    println("N3: ", counts["N3"])
    println("N4: ", counts["N4"])
    println("N5: ", counts["N5"])

    results_entry = Dict(
        "file" => name[i],
        "N1" => counts["N1"],
        "N2" => counts["N2"],
        "N3" => counts["N3"],
        "N4" => counts["N4"],
        "N5" => counts["N5"]
    )
    push!(results, results_entry)
end


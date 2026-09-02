using Pkg
Pkg.add("JSON")
using JSON
path = "C:\\Users\\anjas\\Desktop\\project\\Julia_Projekt\\data\\json\\kanji\\n5.json"
data = JSON.parsefile(path) # liest die JSON-Datei und gibt ein Array von Dictionaries zurück

println(data[1])   # first entry
println(keys(data[1]))  # field names
println(data[1]["character"])  # first kanji character
println(data[1]["level"])  # level of the first kanji character

using JSON

base_dir = "C:\\Users\\anjas\\Desktop\\project\\Julia_Projekt\\data\\json\\kanji"
"""
Finds the level of a given kanji character across all JSON files in the specified directory.
"""
function find_kanji_level(character::String)
    for file in readdir(base_dir; join=true) # readdir liest alle Dateien im Verzeichnis; join=true gibt den vollständigen Pfad zurück
        data = JSON.parsefile(file)

        for entry in data
            if entry["character"] == character
                println("Kanji: ", character, " | Level: ", entry["level"])
                return entry["level"]
            end
        end
    end

    return nothing
end

result = find_kanji_level("一")
println("Ergebnis: ", result)
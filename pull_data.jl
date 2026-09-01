using Pkg
Pkg.add("JSON")
using JSON
path = "C:\\Users\\anjas\\Desktop\\project\\Julia_Projekt\\data\\json\\kanji\\n5.json"
data = JSON.parsefile(path)

println(data[1])   # first entry
println(keys(data[1]))  # field names
println(data[1]["character"])  # first kanji character
println(data[1]["level"])  # level of the first kanji character
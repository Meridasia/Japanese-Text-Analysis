# JuliaProjekt

JuliaProjekt measures Japanese kanji coverage in text using JLPT levels N5 through N1. It can analyze text files, report comprehension thresholds, group results by filename tags, and create comparison plots.

## Requirements

- Julia 1.12 or newer

The JLPT kanji data is stored in `data/json/kanji/`. Input text files belong in `input/`; generated JSON and plot files are written to `output/`.

## Install and test

From the project directory:

```julia
using Pkg
Pkg.instantiate()
Pkg.test()
```

## Use as a package

```julia
using JuliaProjekt

levels = load_kanji_levels("data/json/kanji")
result = analyze("日本語を勉強します。", levels)
println(result["unknown kanji"])
```

The main public functions are:

- `load_kanji_levels(directory)` loads the JLPT lookup table.
- `analyze(text, kanji_levels)` calculates counts, percentages, and coverage thresholds.
- `summarize(results, tags)` summarizes files selected by filename tags.
- `run_analysis(input_dir, kanji_dir, output_dir)` processes new input files and writes JSON output.
- `plot_total(data_file, output_file)` creates the comparison plot from `total.json`.

## Run the included data pipeline

```julia
using JuliaProjekt

run_analysis("input", "data/json/kanji", "output")
plot_total("output/total.json", "output/comparison.png")
```

`run_analysis` skips files already present in `output/results.json`, so it can be run repeatedly as new input is added.

## Project layout

```text
src/JuliaProjekt.jl   Package implementation
test/runtests.jl      Automated tests
data/                 JLPT kanji data
input/                Text files to analyze
output/               Generated results
```

## License

This project is released under the MIT License. See `LICENSE`.

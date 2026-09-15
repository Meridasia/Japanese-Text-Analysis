# KanjiCoverage

KanjiCoverage measures Japanese kanji coverage in text using JLPT levels N5 through N1. It can analyze text files, report comprehension thresholds, group results by filename tags, and create comparison plots.

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
using KanjiCoverage

levels = load_kanji_levels("data/json/kanji")
result = analyze("日本語を勉強します。", levels)
println(result["working level"])
```

The main public functions are:

- `load_kanji_levels(directory)` loads the JLPT lookup table.
- `is_kanji(character)` checks whether a character belongs to a common CJK ideograph block.
- `analyze(text, kanji_levels)` calculates counts, percentages, and coverage thresholds.
- `summarize(results, tags)` summarizes files selected by filename tags.
- `run_analysis(input_dir, kanji_dir, output_dir)` processes new input files and writes JSON output.
- `plot_total(data_file, output_file)` creates the comparison plot from `total.json`.

## Run the included data pipeline

```julia
using KanjiCoverage

run_analysis("input", "data/json/kanji", "output")
plot_total("output/total.json", "output/comparison.png")
```

`run_analysis` skips files already present in `output/results.json`, so it can be run repeatedly as new input is added.

## Project layout

```text
src/KanjiCoverage.jl  Package implementation
test/runtests.jl      Automated tests
data/json/kanji       JLPT kanji data
input/                Text files to analyze
output/               Generated results
```

## Licensing

The KanjiCoverage source code is licensed under the MIT License.

The JLPT data in `data/` is derived from
[OpenJLPT](https://github.com/evanclan/OpenJLPT), licensed under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

The data has been adapted for use by KanjiCoverage. Derivative versions of
that data must remain available under CC BY-SA 4.0.

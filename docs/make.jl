using Documenter
using DocumenterCitations
using MimiqCircuitsBase
using Dates

DocMeta.setdocmeta!(MimiqCircuitsBase, :DocTestSetup, :(using MimiqCircuitsBase); recursive=true)

format = Documenter.HTML(
    collapselevel=2,
    prettyurls=get(ENV, "CI", nothing) == "true",
    footer="Copyright 2021-$(year(now())) QPerfect. All rights reserved."
)

pages = Any[
    "Home"=>"index.md",
    "Installation Instructions"=>"installation.md",
    "Library"=>[
        "Contents" => "library/outline.md",
        "List of Operations" => "library/operations.md",
        "Public" => "library/public.md",
        "Internals" => "library/internals.md",
        "Function index" => "library/function_index.md"
    ],
    "References"=>"references.md"
]

bib = CitationBibliography(joinpath(@__DIR__, "src/references.bib"))

makedocs(;
    sitename="MimiqCircuitsBase.jl",
    authors="QPerfect",
    modules=[MimiqCircuitsBase],
    format=format,
    pages=pages,
    clean=true,
    checkdocs=:exports,
    plugins=[bib]
)

deploydocs(
    repo="github.com/qperfect-io/MimiqCircuitsBase.jl.git",
    versions=["stable" => "v^", "v#.#.#", "dev" => "dev"],
    forcepush=true,
    push_preview=true,
    devbranch="main"
)

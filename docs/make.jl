#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
using Documenter
using DocumenterCitations
using MimiqCircuitsBase
using Dates

DocMeta.setdocmeta!(MimiqCircuitsBase, :DocTestSetup, :(using MimiqCircuitsBase); recursive=true)

format = Documenter.HTML(
    collapselevel=2,
    prettyurls=get(ENV, "CI", nothing) == "true",
    footer="Copyright 2022-$(year(now())) University of Strasbourg & QPerfect. All rights reserved."
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

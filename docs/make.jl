using Documenter
push!(LOAD_PATH, "../src/")
using SmartAMLSim

makedocs(
    sitename="SmartAMLSim.jl",
    modules=[SmartAMLSim],
    pages=["index.md", "reference.md"]
)

deploydocs(
    repo="github.com/KrainskiL/SmartAMLSim.jl.git",
    target="build"
)
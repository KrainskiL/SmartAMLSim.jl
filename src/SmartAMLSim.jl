module SmartAMLSim

#dependencies
using Combinatorics
using Distributions
using Ipopt
using JSON
using JuMP
using ProgressMeter
using StatsBase

#source
include("input_types.jl")
include("env.jl")
include("agent_fi.jl")
include("agent_launderer.jl")
include("load_data.jl")
include("sim.jl")

#public API
export load_transactions_distributions
export load_entities
export load_internal_aml_specification
export load_external_aml_specification
export initialize_environment
export validate_env
export initialize_fi_agent
export initialize_laundering_agent
export run_epoch
export run_n_epochs
end # module SmartAMLSim
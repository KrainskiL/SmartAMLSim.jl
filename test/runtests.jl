using Test
using SmartAMLSim

@testset "dummy" begin

    @test 1 == 1

    sim_env = initialize_environment("examples/transactions_graph.txt",
        "examples/entities.txt",
        ' ',
        ',',
        true);
    unique_internals_from_trxs = validate_env(sim_env, true, true)
    fi = initialize_fi_agent(sim_env,
        unique_internals_from_trxs,
        "examples/aml_internal_specification.txt",
        1,
        ',',
        true);
    agent = initialize_laundering_agent("Neutral", "examples/aml_external_specification.txt",
        Dict("Neutral" => identity, "Averse" => log, "Seeking" => (x -> x^2)),
        ',',
        true);
    epoch = SmartAMLSim.run_epoch(sim_env, agent, fi)
    epochs = run_n_epochs(10, sim_env, agent, fi)
end
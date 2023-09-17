"""
    run_epoch(env::SmartAMLSimEnv, launderer::LaunderingAgent, fi::FinancialInstitutionAgent)

Runs one epoch of the simulation which constitutes of:
* generating customers' transactions based on distributions
* calculating alerts and detection probabilities by financial institution
* optimiziation of launderer decision
"""
function run_epoch(env::SmartAMLSimEnv, launderer::LaunderingAgent, fi::FinancialInstitutionAgent)

    epoch_trxs_vec = generate_transactions(env)
    p_internal_map = calculate_alerts(fi, epoch_trxs_vec)
    return optimize_launderer_decision(launderer, fi, p_internal_map)
end

"""
    run_n_epochs(n::Int, env::SmartAMLSimEnv, launderer::LaunderingAgent, fi::FinancialInstitutionAgent)

Runs `n` consecutive epochs and returns statistics for analysis.
"""
function run_n_epochs(n::Int, env::SmartAMLSimEnv, launderer::LaunderingAgent, fi::FinancialInstitutionAgent)
    return [run_epoch(env, launderer, fi) for i in 1:n]
end
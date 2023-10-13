"""
    FinancialInstitutionAgent

Representation of financial institution monitoring transactional network and detecting money laundering with internal AML system and fixed investigation capacity.
"""
mutable struct FinancialInstitutionAgent
    aml_internal_specs::Vector{AMLInternalRule}
    capacity::Int
    entities_to_rules_map::Dict{Int,Dict{Int,Vector{Int}}}
end

"""
    initialize_fi_agent(env::SmartAMLSimEnv,
        unique_internals_from_trxs::Vector{Int},
        aml_internal_spec_filename::String,
        capacity::Int,
        file_sep::Char=',',
        verbose::Bool=false)

Function initializes `FinancialInstitutionAgentloads` by loading internal AML rules from file and mapping transactions to AML rules for improved processing performance.
"""
function initialize_fi_agent(env::SmartAMLSimEnv,
    unique_internals_from_trxs::Vector{Int},
    aml_internal_spec_filename::String,
    capacity::Int,
    file_sep::Char=',',
    verbose::Bool=false)

    aml_int_vec = load_internal_aml_specification(aml_internal_spec_filename, file_sep)
    verbose && println("Internal AML specification successfully loaded")

    #Prepare mapping of transactions distributions to internal AML rules - memoization for improved performance
    clients_to_rules_map = Dict{Int,Dict{Int,Vector{Int}}}()
    n_int_aml_rules = length(aml_int_vec)
    #Initialize empty mapping
    for id in unique_internals_from_trxs
        clients_to_rules_map[id] = Dict([i => Int[] for i in 1:n_int_aml_rules])
    end
    #Assign distributions indices to AML rules and customers
    @showprogress 1 "Transactions processed..." for (trx_idx, trx) in enumerate(env.transactions_distributions)
        for (aml_idx, aml_rule) in enumerate(aml_int_vec)
            if (aml_rule.side == 'D')
                if (env.entities[trx.originator_entity_id].type == 'I')
                    if startswith(env.entities[trx.beneficiary_entity_id].business_type, aml_rule.business_type) || (aml_rule.business_type == "All")
                        push!(clients_to_rules_map[trx.originator_entity_id][aml_idx], trx_idx)
                    end
                end
            else
                if (env.entities[trx.beneficiary_entity_id].type == 'I')
                    if startswith(env.entities[trx.originator_entity_id].business_type, aml_rule.business_type) || (aml_rule.business_type == "All")
                        push!(clients_to_rules_map[trx.beneficiary_entity_id][aml_idx], trx_idx)
                    end
                end
            end
        end
    end
    verbose && println("Transactions successfully mapped to internal AML rules.")

    return FinancialInstitutionAgent(aml_int_vec, capacity, clients_to_rules_map)
end

"""
    calculate_alerts(fi::FinancialInstitutionAgent,
        epoch_trxs_vec::Vector{Float64},
        calculate_probabilities::Bool=true)

Counts how many customers breached 1,2,...,n internal AML rules.
By defualt, FI's capacity is used to calculate probability of detection for each number of rules breached.
"""
function calculate_alerts(fi::FinancialInstitutionAgent,
    epoch_trxs_vec::Vector{Float64},
    calculate_probabilities::Bool=true)

    breached_rules_vec = Int[]
    for d in values(fi.entities_to_rules_map)
        n_breached = 0
        for (rule_id, trx_idx_vec) in d
            if sum(epoch_trxs_vec[trx_idx_vec]) >= fi.aml_internal_specs[rule_id].amount
                n_breached += 1
            end
        end
        push!(breached_rules_vec, n_breached)
    end
    breached_count_map = countmap(breached_rules_vec)
    !calculate_probabilities && return breached_count_map

    n_rules = length(fi.aml_internal_specs)
    p_internal_map = Dict(0 => 0.0)
    remaining_capacity = fi.capacity
    for i in n_rules:-1:1
        remaining_capacity -= get(breached_count_map, i, 0)
        if remaining_capacity > 0
            p_internal_map[i] = 1.0
        else
            remaining_breaches = sum([get(breached_count_map, j, 0) for j in 1:i])
            p_internal = (remaining_capacity + get(breached_count_map, i, 0)) / remaining_breaches
            for j in 1:i
                p_internal_map[j] = p_internal
            end
            break
        end
    end
    return p_internal_map
end

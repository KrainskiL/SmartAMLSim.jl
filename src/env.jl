"""
    SmartAMLSimEnv

Simulation environment holding information about distributions of customers' transactions.
"""
struct SmartAMLSimEnv
    transactions_distributions::Vector{TransactionDistribution}
    entities::Dict{Integer,Entity}
end

"""
    initialize_environment(
        transactions_filename::String,
        entities_filename::String,
        transactions_sep::Char=' ',
        other_sep::Char=',',
        verbose::Bool=false
    )

Parses input data and initiliaze simulation's environment object for further processing.
"""
function initialize_environment(
    transactions_filename::String,
    entities_filename::String,
    transactions_sep::Char=' ',
    other_sep::Char=',',
    verbose::Bool=false
)

    #Load file-based inputs
    trxs_dist_vec = load_transactions_distributions(transactions_filename, transactions_sep)
    verbose && println("Distributions of transactions successfully loaded")

    entities_dict = load_entities(entities_filename, other_sep)
    verbose && println("Entities successfully loaded")

    return SmartAMLSimEnv(trxs_dist_vec, entities_dict)
end

"""
    validate_env(env::SmartAMLSimEnv, return_internal_ids::Bool=false, verbose::Bool=false)

Validate integrity between enitites list and transactions; optionally, returns list of internal customers IDs for initialization of FinancialInstitutionAgent
"""
function validate_env(env::SmartAMLSimEnv, return_internal_ids::Bool=false, verbose::Bool=false)

    unique_entities_from_trxs = unique(collect(Iterators.flatten([(d.originator_entity_id, d.beneficiary_entity_id) for d in env.transactions_distributions])))
    available_entities_ids = keys(env.entities)
    unique_internals_from_trxs = Int[]

    #Validate presence of all entities from transactions graph in entities file
    #Filter out external entities (only internal will be used for internal AML rules in FIAgent init)
    for id in unique_entities_from_trxs
        if !(id in available_entities_ids)
            @error "Entity with ID $(id) present in transactions, but not in entities file."
        end
        if env.entities[id].type == 'I'
            push!(unique_internals_from_trxs, id)
        end
    end
    ninternal = length(unique_internals_from_trxs)
    @assert (ninternal != 0) "Number of internal entities (customers) must be higher than 0"
    verbose && println("Internal entities filtered. There are $(ninternal) unique internal entities in transactions file.")

    return_internal_ids && (return unique_internals_from_trxs)
end

"""
    generate_transactions(env::SmartAMLSimEnv)

Generates customers' transactions for an epoch. Transactions are clipped at 0 as the value can't be negative.
"""
function generate_transactions(env::SmartAMLSimEnv)
    return max.(0, rand.([t.transaction_distribution for t in env.transactions_distributions]))
end
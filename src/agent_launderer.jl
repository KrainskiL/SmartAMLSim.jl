"""
    LaunderingAgent

Representation of money laundering customer of financial institution.
Based on the attitude to risk launderer expose a particular utility function.
Launderer also has a particular specification of external AML systems.
"""
struct LaunderingAgent
    utility_function::Function
    aml_external_specs::Vector{AMLExternalRule}
end

"""
    initialize_laundering_agent(launderer_risk_attitude::String,
    aml_external_spec_filename::String,
    utility_funcs_dict::Dict{String,Function}),
    sep=',',
    verbose=false)

Validates the risk attitude string and translates it to launderer's utility function.
External AML rules are loaded from file and validated.
Returns LaunderingAgent object.
"""
function initialize_laundering_agent(launderer_risk_attitude::String,
    aml_external_spec_filename::String,
    utility_funcs_dict::Dict{String,Function}=Dict("Neutral" => identity, "Averse" => log, "Seeking" => (x -> x^2)),
    sep=',',
    verbose=false)

    allowed_attitudes = keys(utility_funcs_dict)
    @assert (launderer_risk_attitude in allowed_attitudes) "Launderer attitude should be one of: $(join(allowed_attitudes,','))"
    verbose && println("Valid risk attitude was passed")

    aml_ext_vec = load_external_aml_specification(aml_external_spec_filename, sep)
    verbose && println("External AML specification successfully loaded")

    return LaunderingAgent(utility_funcs_dict[launderer_risk_attitude], aml_ext_vec)
end

"""
    optimize_single_problem(agent::LaunderingAgent,
        fi::FinancialInstitutionAgent,
        rules_breached::Vector{Int},
        p_internal::Float64)

Build and optimize single scenario (combination of internal rules breached) for a given epoch.
"""
function optimize_single_problem(agent::LaunderingAgent,
    fi::FinancialInstitutionAgent,
    rules_breached::Vector{Int},
    p_internal::Float64)

    #Divide internal AML rules into Credit and Debit and mark as breached
    credit_int_rules = []
    debit_int_rules = []
    for (idx, rule) in enumerate(fi.aml_internal_specs)
        breached = idx in rules_breached ? true : false
        if rule.side == 'C'
            push!(credit_int_rules, (rule, breached))
        else
            push!(debit_int_rules, (rule, breached))
        end
    end
    n_external = length(agent.aml_external_specs)
    n_credit_internal = length(credit_int_rules)
    model = Model(optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0))
    register(model, Symbol("utility_function"), 1, agent.utility_function; autodiff=true)
    #Decision variables
    ##Debit (outgoing) transactions - each external stream is one variable
    @variable(model, x[1:n_external] >= 0)
    ##Credit (incoming) transactions - each credit rule is one variable
    @variable(model, y[1:n_credit_internal] >= 0)
    #Constraints - outgoing transactions must be equal or lower than incoming transactions
    @constraint(model, sum(x[i] for i in 1:n_external) <= sum(y[i] for i in 1:n_credit_internal))
    #Constraints - transactions must be lower than rules thresholds, to match number of rules breached
    for i in 1:n_external
        btype = agent.aml_external_specs[i].business_type
        idx_internal = findfirst(==(btype), [t.business_type for t in getindex.(debit_int_rules, 1)])
        if isnothing(idx_internal)

        elseif debit_int_rules[idx_internal][2]
            @constraint(model, [1:1], x[i] >= debit_int_rules[idx_internal][1].amount)
        else
            @constraint(model, [1:1], x[i] <= debit_int_rules[idx_internal][1].amount - 1e-4)
        end
    end
    for i in 1:n_credit_internal
        if credit_int_rules[i][2]
            @constraint(model, [1:1], y[i] >= credit_int_rules[i][1].amount)
        else
            @constraint(model, [1:1], y[i] <= credit_int_rules[i][1].amount - 1e-4)
        end
    end
    #Objective function
    obj_expr = NonlinearExpr(:*,
        (1 - p_internal),
        sum(agent.utility_function(x[i] + 1e-6) for i in 1:n_external),
        [(1 - x[i] * agent.aml_external_specs[i].detection_multiplier) for i in 1:n_external]...)
    @NLobjective(model, Max, obj_expr)
    optimize!(model)
    return model
end

"""
    optimize_launderer_decision(agent::LaunderingAgent,
        fi::FinancialInstitutionAgent,
        prob_map::Dict{Int,Float64},
        verbose::Bool=false)

Runs multiple optimisation models for combinations of breached internal AML rules and input probability of detection for each number of rules breached.
Finds transactions specification which maximize expected utility of laundering agent in given epoch.
"""
function optimize_launderer_decision(agent::LaunderingAgent,
    fi::FinancialInstitutionAgent,
    prob_map::Dict{Int,Float64},
    verbose::Bool=false)

    verbose && println("Starting optimisation of launderer's transactional activity in given epoch")
    optimized_variants = []
    for comb in powerset(1:length(fi.aml_internal_specs))
        verbose && println("Calculating combination with breached rules: ", comb)
        p_internal = prob_map[length(comb)]
        if p_internal == 1.0
            verbose && println(comb, " has 1.0 internal probability, omitting optimisation task.")
            continue
        end
        push!(optimized_variants, (optimize_single_problem(agent, fi, comb, p_internal), comb, length(comb), p_internal))
    end
    filter!(x -> (termination_status(x[1]) == LOCALLY_SOLVED && primal_status(x[1]) == FEASIBLE_POINT), optimized_variants)
    opt = argmax((x -> objective_value(x[1])), optimized_variants)
    return (util=objective_value(opt[1]),
        sum_out=sum(round.(value.(opt[1][:x]))),
        sum_in=sum(round.(value.(opt[1][:y]))),
        rules_breached=opt[3],
        p_internal=opt[4])
end
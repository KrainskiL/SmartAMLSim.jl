Reference
=========

```@meta
CurrentModule = SmartAMLSim
DocTestSetup = quote
    using SmartAMLSim
end
```

Input data types
----------------------
```@docs
TransactionDistribution
Entity
AMLInternalRule
AMLExternalRule
```

Data loading functions
----------------------
```@docs
load_transactions_distributions
load_entities
load_internal_aml_specification
load_external_aml_specification
```

Simulation environment
----------------------
```@docs
SmartAMLSimEnv
initialize_environment
validate_env
generate_transactions
```

Financial institution agent
----------------------
```@docs
FinancialInstitutionAgent
initialize_fi_agent
calculate_alerts
```

Launderer agent
----------------------
```@docs
LaunderingAgent
initialize_laundering_agent
optimize_launderer_decision
optimize_single_problem
```

Simulation run
----------------------
```@docs
run_epoch
run_n_epochs
```
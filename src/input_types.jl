"""
    TransactionDistribution

Type to hold the information about distribution of transactions.
"""
struct TransactionDistribution
    originator_entity_id::Int
    beneficiary_entity_id::Int
    transaction_distribution::UnivariateDistribution
end

function TransactionDistribution(
    originator::Int,
    beneficiary::Int,
    param1::Number,
    param2::Number,
    distribution::String)

    try
        TransactionDistribution(originator, beneficiary, eval(Meta.parse("Distributions." * distribution))(param1, param2))
    catch e
        if isa(e, UndefVarError)
            throw(ErrorException("Distribution $(distribution) is not available in Distributions package."))
        else
            rethrow()
        end
    end
end

function TransactionDistribution(
    originator::String,
    beneficiary::String,
    param1::String,
    param2::String,
    distribution::String)

    TransactionDistribution(parse(Int, originator),
        parse(Int, beneficiary),
        parse(Float64, param1),
        parse(Float64, param2),
        distribution)
end

"""
    Entity

Type to hold the information about distribution of transactions.
"""
struct Entity
    type::Char
    business_type::String
end

Entity(type::String, business_type::String) = Entity(only(type), business_type)


"""
    AMLInternalRule

Type representing internal AML rule used by a financial institution.
* `side::Char` - either D or C, for Debit and Credit correspondingly; Credit rule monitor transactions incoming to the internal customer
* `business_type::String` - a keyword matching business type of entities, e.g. ATM, International
* `amount::Number` - threshold value for triggering an alert with a given rule
"""
mutable struct AMLInternalRule
    side::Char
    business_type::String
    amount::Number
end

AMLInternalRule(side::String, type::String, amount::String) = AMLInternalRule(only(side), type, parse(Float64, amount))

"""
    AMLExternalRule

Type representing external AML systems maintained by external financial institutions.
* `business_type::String` - a keyword matching business type of entities, e.g. ATM, International
* `detection_multiplier::Float64` - value of detection multiplier which determines detection chance linearly increasing with the value of outgoing transactions of particular `business_type`
"""
mutable struct AMLExternalRule
    business_type::String
    detection_multiplier::Float64
end

AMLExternalRule(business_type::String, detection_multiplier::String) = AMLExternalRule(business_type, parse(Float64, detection_multiplier))
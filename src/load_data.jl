"""
    load_transactions_distributions(filename::String, sep::Char=' ')

Loads distributions of transactions from provided `filename` into Vector of TransactionDistribution objects.
`sep` is used to split every line of the file.
"""
function load_transactions_distributions(filename::String, sep::Char=' ')
    return [TransactionDistribution(String.(split(line, sep))...) for line in eachline(filename)]
end

"""
    load_entities(filename::String, sep::Char=',')

Loads simulation entities from provided `filename` into dictionary with entity's ID as a key and Entity object as value.
`sep` is used to split every line of the input file.
"""
function load_entities(filename::String, sep::Char=',')
    entities_dict = Dict{Integer,Entity}()
    file_iterator = eachline(filename)
    #Skip header
    first(file_iterator)
    for line in file_iterator
        line_vec = String.(split(line, sep))
        entities_dict[parse(Int, line_vec[1])] = Entity(line_vec[2:end]...)
    end
    return entities_dict
end

"""
    load_internal_aml_specification(filename::String, sep::Char=',')

Loads internal AML rules from provided `filename` into Vector of AMLInternalRule objects.
`sep` is used to split every line of the input file.
"""
function load_internal_aml_specification(filename::String, sep::Char=',')
    file_iterator = eachline(filename)
    #Skip header
    first(file_iterator)
    return [AMLInternalRule(String.(split(line, sep))...) for line in file_iterator]
end

"""
    load_external_aml_specification(filename::String, sep::Char=',')

Loads external AML rules from provided `filename` into Vector of AMLExternalRule objects.
`sep` is used to split every line of the input file.
"""
function load_external_aml_specification(filename::String, sep::Char=',')
    file_iterator = eachline(filename)
    #Skip header
    first(file_iterator)
    return [AMLExternalRule(String.(split(line, sep))...) for line in file_iterator]
end
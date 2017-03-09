import Base.string
import Base.print
import Base.show

export GenieType, GenieController, Controller

abstract GenieType
string{T<:GenieType}(io::IO, t::T) = "$(typeof(t)) <: $(super(typeof(t)))"
print{T<:GenieType}(io::IO, t::T) = print(io, "$(typeof(t)) <: $(super(typeof(t)))")
show{T<:GenieType}(io::IO, t::T) = print(io, genietype_to_print(t))

type GenieController <: GenieType
end

typealias Controller GenieController

function genietype_to_print{T<:GenieType}(m::T) :: String
  output = "\n" * "$(typeof(m))" * "\n"
  output *= string(Genie.config.log_formatted ? Millboard.table(Genie.SearchLight.to_string_dict(m)) : SearchLight.to_string_dict(m) ) * "\n"

  output
end

function to_dict(m::Any) :: Dict{String,Any}
  Dict(string(f) => getfield(m, Symbol(f)) for f in fieldnames(m))
end

function to_string_dict(m::Any; all_output::Bool = false) :: Dict{String,String}
  to_string_dict(m, fieldnames(m), all_output = all_output)
end
function to_string_dict(m::Any, fields::Array{Symbol,1}; all_output::Bool = false) :: Dict{String,String}
  output_length = all_output ? 100_000_000 : Genie.config.output_length
  response = Dict{String,String}()
  for f in fields
    key = string(f)
    value = string(getfield(m, Symbol(f)))
    if length(value) > output_length
      value = value[1:output_length] * "..."
    end
    response[key] = string(value)
  end

  response
end

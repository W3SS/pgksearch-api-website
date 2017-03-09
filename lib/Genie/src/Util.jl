module Util

export expand_nullable, _!!, _!_

function add_quotes(str::String) :: String
  if ! startswith(str, "\"")
    str = "\"$str"
  end
  if ! endswith(str, "\"")
    str = "$str\""
  end

  str
end

function strip_quotes(str::String) :: String
  if is_quoted(str)
    str[2:end-1]
  else
    str
  end
end

function is_quoted(str::String) :: Bool
  startswith(str, "\"") && endswith(str, "\"")
end

function expand_nullable{T}(value::T) :: T
  value
end

function expand_nullable{T}(value::Nullable{T}, default::T) :: T
  if isnull(value)
    default
  else
    Base.get(value)
  end
end

function _!!{T}(value::Nullable{T}) :: T
  Base.get(value)
end

function _!_{T}(value::Nullable{T}, default::T) :: T
  expand_nullable(value, default)
end

function file_name_to_type_name(file_name) :: String
  join(map(x -> ucfirst(x), split(file_name_without_extension(file_name), "_")) , "")
end

function file_name_without_extension(file_name, extension = ".jl") :: String
  file_name[1:end-length(extension)]
end

function walk_dir(dir; monitored_extensions = ["jl"]) :: String
  f = readdir(abspath(dir))
  for i in f
    full_path = joinpath(dir, i)
    if isdir(full_path)
      walk_dir(full_path)
    else
      if ( last( split(i, ['.']) ) in monitored_extensions )
        produce( full_path )
      end
    end
  end
end

end

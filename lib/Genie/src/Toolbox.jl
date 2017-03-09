module Toolbox

using Genie, Util, Millboard, FileTemplates, Configuration, Logger

type TaskInfo
  file_name::String
  module_name::Symbol
  description::String
end

function run_task(task_type_name)
  tasks = all_tasks(filter_type_name = Symbol(task_type_name))

  isempty(tasks) && (Logger.log("Task not found", :err) & return)
  eval(tasks[1].module_name).run_task!()
end

function print_all_tasks() :: Void
  output = ""
  arr_output = []
  for t in all_tasks()
    td = Genie.to_dict(t)
    push!(arr_output, [td["type_name"], td["file_name"], td["description"]])
  end

  Millboard.table(arr_output, :colnames => ["Task name \nFilename \nDescription "], :rownames => []) |> println

  nothing
end

function all_tasks(; filter_type_name = Symbol()) :: Vector{TaskInfo}
  tasks = TaskInfo[]

  tasks_folder = abspath(Genie.config.tasks_folder)
  f = readdir(tasks_folder)
  for i in f
    if ( endswith(i, "Task.jl") )
      push!(LOAD_PATH, tasks_folder)

      module_name = Util.file_name_without_extension(i) |> Symbol
      eval(:(using $(module_name)))
      ti = TaskInfo(i, module_name, eval(module_name).description())

      if ( filter_type_name == Symbol() ) push!(tasks, ti)
      elseif ( filter_type_name == module_name ) return TaskInfo[ti]
      end
    end
  end

  tasks
end

function new(cmd_args::Dict{String,Any}, config::Settings) :: Void
  tfn = task_file_name(cmd_args, config)

  if ispath(tfn)
    error("Task file already exists")
  end

  f = open(tfn, "w")
  write(f, FileTemplates.new_task(task_class_name(cmd_args["task:new"])))
  close(f)

  Logger.log("New task created at $tfn")

  nothing
end

function task_file_name(cmd_args::Dict{String,Any}, config::Settings) :: String
  joinpath(config.tasks_folder, cmd_args["task:new"] * ".jl")
end

function task_class_name(underscored_task_name::String) :: String
  mapreduce( x -> ucfirst(x), *, split(replace(underscored_task_name, ".jl", ""), "_") )
end

end

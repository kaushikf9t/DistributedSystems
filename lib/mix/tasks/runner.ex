defmodule Mix.Tasks.Runner do                            #Trigger module, called from the command line with arguments
  use Mix.Task

  def run([]) do                                         #Check for arguments passed from command line
    IO.puts "Please provide two arguments"                
  end
  
  def run(args) do
    {_, params, _}= OptionParser.parse(args, strict: [debug: :boolean])
    no_args = length(params)
    if no_args === 2 do                                 #Check if only 2 arguments are passed
    	[argval1 | rest] = params
    	[argval2 | []] = rest
    	{arg_n, ""} = Integer.parse(argval1)
    	{arg_k, ""} = Integer.parse(argval2)
    	if arg_n < 0 || arg_k < 0 do                      #Check if arguements are positive
    		IO.puts "Please provide positive numbers as arguments"
    	else
    		Mix.Tasks.Boss.start_link(arg_n, arg_k)         #Call the BOSS module
    	end
    else
    	IO.puts "Please enter two arguments"
    end
  end 
  
end

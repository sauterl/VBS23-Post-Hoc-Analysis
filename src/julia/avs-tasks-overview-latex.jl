using JSON3, CSV, DataFrames, JSONTables, Latexify;

tasks = DataFrame(CSV.File("data/processed/avs-tasks.csv"));

# Task name beautification since the prefix 'vbs23-avs' is too cumbersome for the paper
tasks.name = replace.(tasks.name, "vbs23-avs" => "a");

# Clean up text
tasks.hint = replace.(tasks.hint, "\n" => "");
tasks.hint = replace.(tasks.hint, "\t" => "");
tasks.hint = rstrip.(tasks.hint);

# Latex tableify
tex = latexify(tasks[:,[:name,:hint]], env=:table,latex=false);

open("tex/avs-tasks.tex", "w") do f
    write(f, tex);
end
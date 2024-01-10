using CSV, DataFrames, DataFramesMeta
using ColorSchemes, ColorBrewer
using CairoMakie

scores = CSV.read("data/raw/scores-vbsofficial2023.csv", DataFrame)
scores = scores[scores[:, :team] .!== String15("unitedjudges"), :]
scores[!, :task] = replace.(scores[:, :task], "vbs23-" => "")
scores[scores[:, :team] .== "HTW", :team] .= "vibro"

tasks = unique(scores[:, :task])
scores[!, :task_nr] = map(x -> findfirst(h -> h == x, tasks), scores[:, :task])
sort!(scores, [:task_nr, :team])

team_count = length(unique(scores[:, :team]))
task_count = length(tasks)

task_groups = unique(scores[:, :group])
task_group_symbols = Symbol.(task_groups)

score_sums = DataFrame(merge(Dict("task_nr" => scores[:, :task_nr], "team" => scores[:, :team]), Dict(zip(task_groups, [0 for i in task_groups]))))
sort!(score_sums, [:task_nr, :team])

sum_groups = groupby(score_sums, :task_nr)
score_groups = groupby(scores, :task_nr)

#populate
for i in 1:length(score_groups)
    sum_groups[i][!, Symbol(score_groups[i][1, :group])] = score_groups[i][:, :score]
end

#cumsum
for g in groupby(score_sums, :team)
    for s in task_group_symbols
        g[!, s] = cumsum(g[!, s])
    end
end

#normalize
score_sums_normalized = DataFrame(score_sums)
for g in groupby(score_sums_normalized, :task_nr)
    for s in task_group_symbols
        n = max(1, maximum(g[!, s])) / 1000
        g[!, s] ./= n
    end
end

#sum
score_sums[!, :sum] = sum.(eachrow(score_sums[:, task_group_symbols]))
score_sums_normalized[!, :sum] = sum.(eachrow(score_sums_normalized[:, task_group_symbols]))

#rank
score_sums_normalized[!, :rank] .= 0
for g in groupby(score_sums_normalized, :task_nr)
    g[sortperm(g[:, :sum], rev = true), :rank] = collect(1:team_count)
end


team_names = sort(groupby(score_sums_normalized, :task_nr)[end], :sum, rev = true)[:, :team]

colors = Dict(zip(team_names, get(ColorSchemes.corkO, collect(0:1/(team_count-1):1))))

linetypes = Dict(zip(team_names, [:solid, :dash, :dot, :solid, :dash, :dot, :solid, :dash, :dot, :solid, :dash, :dot, :solid, :dash]))


#rank vs time
fig = Figure()
Axis(fig[1, 1], xlabel = "Task", ylabel = "Team Rank", yticks = 1:team_count, xticks = 2:2:task_count, xminorticks = IntervalsBetween(2), xminorgridvisible = true, yreversed = true)
for g in groupby(score_sums_normalized, :team)
    lines!( g[:, :task_nr],  g[:, :rank], color = colors[g[1, :team]], linewidth = 2, linestyle = linetypes[g[1, :team]])
end

Legend(fig[1,2], [LineElement(color = colors[t], linestyle = linetypes[t], linewidth = 2) for t in team_names], team_names, "Team", orientation = :vertical, framevisible = false)

save("plots/team_rank_vs_time.pdf", fig)


#normalized score vs time
fig = Figure()
Axis(fig[1, 1], xlabel = "Task", ylabel = "Normalized total score", yticks = 0:500:(1000*length(task_groups)), xticks = 2:2:task_count, xminorticks = IntervalsBetween(2), xminorgridvisible = true,)
for g in groupby(score_sums_normalized, :team)
    lines!( g[:, :task_nr],  g[:, :sum], color = colors[g[1, :team]], linewidth = 2, linestyle = linetypes[g[1, :team]])
end

Legend(fig[1,2], [LineElement(color = colors[t], linestyle = linetypes[t], linewidth = 2) for t in team_names], team_names, "Team", orientation = :vertical, framevisible = false)

save("plots/normalized_score_vs_time.pdf", fig)

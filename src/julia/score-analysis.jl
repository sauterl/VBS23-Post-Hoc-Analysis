using JSON, CSV, DataFrames, DataFramesMeta
using ColorSchemes, ColorBrewer
using CairoMakie

run = JSON.parsefile("data/raw/vbs23_run.json")
scores = CSV.read("data/raw/scores-vbsofficial2023.csv", DataFrame)

team_id_to_name = Dict(map(x -> x["uid"]["string"] => x["name"], run["description"]["teams"]))
tasks = filter(x -> length(x["submissions"]) > 0, run["tasks"])

countdown_offset = 5000 #subtract the 5 second init/countdown period from the task start to be consistent with analysis performed in other sections

submissions = DataFrame[]

for t in tasks

    task_name = t["description"]["name"]
    task_group = t["description"]["taskGroup"]["name"]
    task_start = t["started"] + countdown_offset

    for s in t["submissions"]
        push!(submissions, DataFrame(
            task = task_name,
            group = task_group,
            time = s["timestamp"] - task_start,
            team = team_id_to_name[s["teamId"]["string"]],
            member = s["memberId"]["string"],
            item = s["item"]["name"],
            start = s["start"],
            ending = s["end"],
            status = s["status"]
        ))
    end

end

submissions = vcat(submissions...)

submissions[!, :group] = replace.(submissions[:, :group], "vbs23-" => "")

task_type_count = 4
team_count = 13


scores[scores[:, :team] .== "HTW", :team] .= "vibro"
submissions[submissions[:, :team] .== "HTW", :team] .= "vibro"


## total scores
score_sum = combine(groupby(scores, [:team, :group]), :score => sum)

score_sum = score_sum[score_sum[:, :team] .!== String15("unitedjudges"), :]

g = groupby(score_sum, :group)
foreach(x -> x[:, :score_sum] = 1000 * x[:, :score_sum] ./ maximum(x[:, :score_sum]), g)
score_sum_normalized = combine(g, :)

sort!(score_sum_normalized, :group)

oder = sort(combine(groupby(score_sum_normalized, :team), :score_sum => sum => :sum), :sum, rev = true)[:, :team]

score_sum_normalized = @rorderby score_sum_normalized findfirst(==(:team), oder)

pos = collect(Iterators.flatten(([[i, i, i, i] for i in 1:team_count])))
grp = collect(Iterators.flatten(([[1, 2, 3, 4] for i in 1:team_count])))
team_names = unique(score_sum_normalized[:, :team])

colors = palette("Set1", task_type_count)

fig = Figure()

ax = Axis(fig[1, 1],
xlabel = "Team",
ylabel = "Score",
xticks = (1:team_count, team_names),
yticks = 0:200:1000,
xticklabelrotation = pi/4,
title = "")

barplot!(
    pos, score_sum_normalized[:, :score_sum],
    dodge = grp,
    color = colors[grp]
)

labels = score_sum_normalized[1:task_type_count, :group]

Legend(fig[2,1], [PolyElement(polycolor = colors[i]) for i in 1:task_type_count], labels, "Task Type", orientation = :horizontal, framevisible = false)

save("plots/score_sum.pdf", fig)



## correct/wrong submissions per team

#count only one correct submission for KIS tasks
submissions_per_team_task = combine(groupby(submissions, [:team, :group, :status, :task]), :status => length => :count)
duplicates = (submissions_per_team_task[:, :group] .!== "AVS") .& (submissions_per_team_task[:, :status] .== "CORRECT") .& (submissions_per_team_task[:, :count] .> 1)
submissions_per_team_task[duplicates, :count] = repeat([1], sum(duplicates))

submissions_per_team = combine(groupby(submissions_per_team_task, [:team, :group, :status]), :count => sum => :count)
sort!(submissions_per_team, [:group, :status])
submissions_per_team = @rorderby submissions_per_team findfirst(==(:team), oder)

kis = submissions_per_team[submissions_per_team[:, :group] .!== "AVS", :]
kis[!, :key] = map(x -> "$(x[:group]) - $( x[:status] == "CORRECT" ? "Correct" : "Total" )", eachrow(kis))

#hack to populate missing combinations with 0
h = collect(Iterators.product(unique(kis[:, :team]), unique(kis[:, :key])))[:]
kis = vcat(kis, DataFrame(team = map(x -> x[1], h), group = "", status = "", count = 0, key = map(x -> x[2], h)))

kis = combine(groupby(kis, [:team, :key]), :count => sum => :count)
sort!(kis, :key)
kis = @rorderby kis findfirst(==(:team), oder)


pos = collect(Iterators.flatten(([[i, i, i, i, i, i] for i in 1:team_count])))
dodge = collect(Iterators.flatten(([[1, 1, 2, 2, 3, 3] for i in 1:team_count])))
stack = collect(Iterators.flatten(([[1, 1, 1, 1, 1, 1] for i in 1:team_count])))
col = collect(Iterators.flatten(([[1, 2, 3, 4, 5, 6] for i in 1:team_count])))
colors = palette("Paired", 10)
colors = colors[[2,1,4,3,10,9]]

fig = Figure()

ax = Axis(fig[1, 1],
xlabel = "Team",
ylabel = "Number of Submissions",
xticks = (1:team_count, team_names),
yticks = (0:2:14),
xticklabelrotation = pi/4,
title = "")

barplot!(ax,
    pos, kis[:, :count],
    dodge = dodge,
    stack = stack,
    color = colors[col]
)

labels = kis[1:6, :key]

Legend(fig[2,1], [PolyElement(polycolor = colors[i]) for i in 1:6], labels, "Task Type", orientation = :horizontal, framevisible = false, nbanks = 2)

save("plots/kis_status_count.pdf", fig)


avs = submissions_per_team[submissions_per_team[:, :group] .== "AVS", :]

#hack to populate missing combinations with 0
h = collect(Iterators.product(unique(avs[:, :team]), unique(avs[:, :status])))[:]
avs = vcat(avs, DataFrame(team = map(x -> x[1], h), group = "AVS", status = map(x -> x[2], h), count = 0))

avs = combine(groupby(avs, [:team, :status]), :count => sum => :count)
avs = @rorderby avs findfirst(==(:team), oder)


pos = collect(Iterators.flatten(([[i, i, i] for i in 1:team_count])))
grp = collect(Iterators.flatten(([[1, 2, 3] for i in 1:team_count])))
colors = palette("Set2", 4)

fig = Figure()

ax = Axis(fig[1, 1],
xlabel = "Team",
ylabel = "Number of Submissions",
xticks = (1:team_count, team_names),
yticks = (0:100:500),
xticklabelrotation = pi/4,
title = "")

barplot!(ax,
    pos, avs[:, :count],
    dodge = grp,
    color = colors[grp]
)

labels = avs[1:3, :status]

Legend(fig[2,1], [PolyElement(polycolor = colors[i]) for i in 1:3], labels, "Status", orientation = :horizontal, framevisible = false)

save("plots/avs_status_count.pdf", fig)



## time until first (correct) submission per team and type

time_to_first_submission = combine(groupby(submissions, [:team, :group, :task]), :time => minimum => :first)

time_to_first_submission[!, :first] ./= 60_000

sort!(time_to_first_submission, :group)

time_to_first_submission = @rorderby time_to_first_submission findfirst(==(:team), oder)


colors = palette("Set1", 4)

team_to_id = Dict(zip(oder, collect(1:team_count)))
xs = map(x -> get(team_to_id, x, 0), time_to_first_submission[:, :team])

type_to_id = Dict(["AVS" => 1, "KIS-T" => 2, "KIS-V" => 3, "KIS-V-M" => 4])
dodge = map(x -> get(type_to_id, x, 0), time_to_first_submission[:, :group])

marker_dict = Dict(1 => :circle, 2 => :rect, 3 => :diamond, 4 => :star4)

marker = map(x -> marker_dict[x], dodge)

fig = Figure()

ax = Axis(fig[1, 1],
xlabel = "Team",
ylabel = "Minutes",
xticks = (1:team_count, team_names),
yticks = (0:1:8),
xticklabelrotation = pi/4,
title = "")

points = Point2f.(xs .+ (0.15 .* dodge) .- 0.375, time_to_first_submission[:, :first])

scatter!(ax, points, color = colors[dodge], marker = marker)

labels = ["AVS", "KIS-T", "KIS-V", "KIS-V-M"]

Legend(fig[2,1], [PolyElement(polycolor = colors[i]) for i in 1:4], labels, "Task Type", orientation = :horizontal, framevisible = false)

save("plots/time_to_first_submission.pdf", fig)



time_to_first_correct_submission = combine(groupby(submissions[submissions[:, :status] .== "CORRECT", :], [:team, :group, :task]), :time => minimum => :first)

time_to_first_correct_submission[!, :first] ./= 60_000

sort!(time_to_first_correct_submission, :group)

time_to_first_correct_submission = @rorderby time_to_first_correct_submission findfirst(==(:team), oder)

xs = map(x -> get(team_to_id, x, 0), time_to_first_correct_submission[:, :team])
dodge = map(x -> get(type_to_id, x, 0), time_to_first_correct_submission[:, :group])

marker = map(x -> marker_dict[x], dodge)

fig = Figure()

ax = Axis(fig[1, 1],
xlabel = "Team",
ylabel = "Minutes",
xticks = (1:team_count, team_names),
yticks = (0:1:8),
xticklabelrotation = pi/4,
title = "")

points = Point2f.(xs .+ (0.15 .* dodge) .- 0.375, time_to_first_correct_submission[:, :first])

scatter!(ax, points, color = colors[dodge], marker = marker)

labels = ["AVS", "KIS-T", "KIS-V", "KIS-V-M"]

Legend(fig[2,1], [PolyElement(polycolor = colors[i]) for i in 1:4], labels, "Task Type", orientation = :horizontal, framevisible = false)

save("plots/time_to_first_correct_submission.pdf", fig)
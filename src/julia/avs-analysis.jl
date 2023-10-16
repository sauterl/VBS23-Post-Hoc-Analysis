using CSV, DataFrames, CairoMakie, CategoricalArrays, Statistics;
using ColorSchemes, ColorBrewer;
include("./src/julia/vbsanalysis.lib.jl")
using .VbsAnalysis

subs = DataFrame(CSV.File("data/processed/avs-submissions.csv"));

# ---------------------------------------------------
# Analysis ratios of submisisons per team (like in 2022)
# ---------------------------------------------------
# Group by task and team, count (nrow) and get the unique values on task and team. See https://dataframes.juliadata.org/stable/lib/functions/#DataFrames.combine or https://juliadatascience.io/groupby_combine
subsPerTaskTeam = unique(combine(groupby(subs, [:task, :team]), :, nrow), [:task, :team]);
# Sum up to get the total of the submissions per task and rename to sum
totals = combine(groupby(subsPerTaskTeam, [:task]), :nrow .=> sum => :sum);
# Join on the taks (name)
df = innerjoin(subsPerTaskTeam, totals, on = :task);
# Calculate ratio total per task and team / totals
df.ratio = df.nrow ./ df.sum;

# Clean HTW to vibro name
df.team = replace.(df.team, "HTW" => "vibro")

# Makie works better with categorical arrays, hence we convert the relevant columns to categorical
df.task = categorical(df.task);
df.team = categorical(df.team);


# Plotting setup
fig = Figure();
# Axis
ax = Axis(fig[1,1],             # Placement within the figure [1,1] is top left
xticks = (                      # The x ticks
    1:length(levels(df.task)),  # Numerical version of xticks, basically indices for label (next argument)
    replace.(levels(df.task), "vbs23-avs" => "a")),                    # The labels to draw from (with the indices of the previous argument).
title="Shares of submissions per team and task"
);
# Makie stacked barplot of the shares of submissions per team and task

# Use sorting of official ranks at the end. team_names are sorted and since stacks are inverted, we use this numbering
stacks = maximum(indexin(df.team, team_names))+1 .- indexin(df.team,team_names)

barplot!(ax,                    # The axis
    df.task.refs,               # The x values, must be numerical, hence the refs. Multiple equal X values result in stacks
    df.ratio,                   # The Y values, must be numerical, this is the share of submissions of a team (bar) for the given task (x tick)
    stack=stacks,         # Numerical value of stack ordering
    color=[team_colours[t] for t in df.team],     # Numerical colour value within the theme (we use the same values as for the stacking)
    #bar_labels=df.team         # Apparently, categorical array works here, basically all the labels for all the bars (remember, they get stacked) # DISABLED, since unreadable
);
# The Legend with reversed entries due to the way of the stacking
Legend(fig[1,2],       # Placement within the figure: to the right of fig[1,1]
    team_legendelements,  # Colour elements aka squares
    team_names,     # The labels, i.e. the teams
    "Teams"             # Title of the legend
    );

# Saving the plot on disk using default size measurements
save("plots/avs-team-ratios-total.pdf", fig);

# ---------------------------------------------------
# Analysis of correct submissions per team (n times the same segment counts as n)
# ---------------------------------------------------
csubs = filter(:status => s->s == "CORRECT", subs);
# Group by task and team, count (nrow) and get the unique values on task and team
csubsPerTaskTeam = unique(combine(groupby(csubs, [:task, :team]), :, nrow), [:task, :team]);
# Sum up to get the total of the submissions per task and rename to sum
ctotals = combine(groupby(csubsPerTaskTeam, [:task]), :nrow .=> sum => :sum);
# Join on the taks (name)
cdf = innerjoin(csubsPerTaskTeam, ctotals, on = :task);
# Calculate ratio total per task and team / totals
cdf.ratio = cdf.nrow ./ cdf.sum;
# Clean Team naming
cdf.team = replace.(cdf.team, "HTW" => "vibro")
# Makie works better with categorical arrays, hence we convert the relevant columns to categorical
cdf.task = categorical(cdf.task);
cdf.team = categorical(cdf.team);

cstacks = maximum(indexin(cdf.team, team_names))+1 .- indexin(cdf.team,team_names)

# Plotting setup
cfig = Figure();
# Axis
cax = Axis(cfig[1,1],             # Placement within the figure [1,1] is top left
xticks = (                      # The x ticks
1:length(levels(cdf.task)),  # Numerical version of xticks, basically indices for label (next argument)
replace.(levels(cdf.task), "vbs23-avs" => "a")),                    # The labels to draw from (with the indices of the previous argument).
title="Shares of submissions per team and task"
);
# Makie stacked barplot of the shares of submissions per team and task
barplot!(cax,                    # The axis
cdf.task.refs,               # The x values, must be numerical, hence the refs. Multiple equal X values result in stacks
cdf.ratio,                   # The Y values, must be numerical, this is the share of submissions of a team (bar) for the given task (x tick)
stack=cstacks,         # Numerical value of stack ordering
color=[team_colours[t] for t in cdf.team], # Numerical colour value within the theme (we use the same values as for the stacking)
#bar_labels=df.team         # Apparently, categorical array works here, basically all the labels for all the bars (remember, they get stacked) # DISABLED, since unreadable
);
# The Legend with reversed entries due to the way of the stacking
Legend(cfig[1,2],       # Placement within the figure: to the right of fig[1,1]
team_legendelements,  # Colour elements aka squares
team_names,     # The labels, i.e. the teams
"Teams"             # Title of the legend
);

# Saving the plot on disk using default size measurements
save("plots/avs-team-ratios-correct.pdf", cfig);

# ---------------------------------------------------
# Analysis of correct submissions with unique item (i.e. video) per team
#   (k times video v for team t counts as 1, in case multiple teams have sumitted the same segment, this is not filtered)
# ---------------------------------------------------
# Group by task and team and item, count (nrow) and get the unique values on task and team
csubsPerTaskTeamItems = unique(combine(groupby(csubs, [:task, :team, :item]), :, nrow), [:task, :team, :item]);
# We want to only count one submission per item (technically the first, however we are calculating ratios here, so it doesn't matter
csubsPerTaskTeamItems.nrow .= 1;
# Like previously, aggregate on task-team uniqueness
cisubSperTaskTeam = unique(combine(groupby(csubsPerTaskTeamItems, [:task,:team]), : ,nrow), [:task, :team]);
# Sum up to get the total of the submissions per task and rename to sum
citotals = combine(groupby(cisubSperTaskTeam, [:task]), :nrow .=> sum => :sum);
# Join on the taks (name)
cidf = innerjoin(cisubSperTaskTeam, citotals, on = :task);
# Calculate ratio total per task and team / totals
cidf.ratio = cidf.nrow ./ cidf.sum;
# Clean Team naming
cidf.team = replace.(cidf.team, "HTW" => "vibro");
# Makie works better with categorical arrays, hence we convert the relevant columns to categorical
cidf.task = categorical(cidf.task);
cidf.team = categorical(cidf.team);

cistacks = maximum(indexin(cidf.team, team_names))+1 .- indexin(cidf.team,team_names);

# Plotting setup
cifig = Figure();
# Axis
ciax = Axis(cifig[1,1],             # Placement within the figure [1,1] is top left
xticks = (                      # The x ticks
1:length(levels(cidf.task)),  # Numerical version of xticks, basically indices for label (next argument)
replace.(levels(cidf.task), "vbs23-avs" => "a")),                    # The labels to draw from (with the indices of the previous argument).
title="Shares of first correct submissions per team and task"
);
# Makie stacked barplot of the shares of submissions per team and task
barplot!(ciax,                    # The axis
cidf.task.refs,               # The x values, must be numerical, hence the refs. Multiple equal X values result in stacks
cidf.ratio,                   # The Y values, must be numerical, this is the share of submissions of a team (bar) for the given task (x tick)
stack=cistacks,         # Numerical value of stack ordering
color=[team_colours[t] for t in cidf.team], # Numerical colour value within the theme (we use the same values as for the stacking)
#bar_labels=df.team         # Apparently, categorical array works here, basically all the labels for all the bars (remember, they get stacked) # DISABLED, since unreadable
strokecolor= :white, # Have a white border and see whether this makes it more readable
strokewidth= 0.1, # have a width for the stroke to enhance readability # this looks horrible
#offset= 0.1,
);
# The Legend with reversed entries due to the way of the stacking
Legend(cifig[1,2],       # Placement within the figure: to the right of fig[1,1]
team_legendelements,  # Colour elements aka squares
team_names,     # The labels, i.e. the teams
"Teams"             # Title of the legend
);

# Saving the plot on disk using default size measurements
save("plots/avs-team-ratios-correct-single-item.pdf", cifig);




# ---------------------------------------------------
# Analysis of unique submissions
# ---------------------------------------------------
# Group by task and item, count (nrow) and get the unique values on task and item
subsPerTaskItem = unique(combine(groupby(subs, [:task, :item]), :, nrow), [:task, :item]);
# Group by task and segment (item,start,ending), count and get unique values.
subsPerTaskUnique = unique(combine(groupby(subs, [:task, :item, :start, :ending]), :, nrow), [:task, :item, :start, :ending]);
csubsPerTaskUnique = unique(combine(groupby(filter(:status => s->s == "CORRECT", subs), [:task, :item, :start, :ending]), :, nrow), [:task, :item, :start, :ending]);
wsubsPerTaskUnique = unique(combine(groupby(filter(:status => s->s == "WRONG", subs), [:task, :item, :start, :ending]), :, nrow), [:task, :item, :start, :ending]);

# Get the extrema per task (i.e. max and min per task and unique segments
stats = combine(groupby(subsPerTaskUnique, [:task]), :nrow => (x -> [extrema(x)]) => [:min, :max]);
cstats =combine(groupby(csubsPerTaskUnique, [:task]), :nrow => (x -> [extrema(x)]) => [:min, :max]);
wstats =combine(groupby(wsubsPerTaskUnique, [:task]), :nrow => (x -> [extrema(x)]) => [:min, :max]);
# join on the task and max to get the segement (item,start,ending) (and do some projection to only have relevant information)
statsWithItem = innerjoin(subsPerTaskUnique, stats, on= [:task => :task, :nrow => :max])[:,[:task, :item, :start, :ending, :status, :nrow]]
cstatsWithItem = innerjoin(csubsPerTaskUnique, cstats, on= [:task => :task, :nrow => :max])[:,[:task, :item, :start, :ending, :status, :nrow]]
wstatsWithItem = innerjoin(wsubsPerTaskUnique, wstats, on= [:task => :task, :nrow => :max])[:,[:task, :item, :start, :ending, :status, :nrow]]


# ---------------------------------------------------
# Analysis of submission density
# ---------------------------------------------------
avsSubs = DataFrame(CSV.File("data/processed/avs-submissions.csv"));
avsSubs.task = categorical(avsSubs.task);
avsSubs.time = avsSubs.time ./ 1000;
subsPerTask = groupby(avsSubs, [:task]);
csubsPerTask = groupby(filter(:status => s->s == "CORRECT", avsSubs), [:task]);

avsTasks = levels(avsSubs.task)

# Sampling color scheme. values must be between 0 and 1, hence the division
densityColors = get(ColorSchemes.roma, collect(0:1/(length(avsTasks)-1):1));

densityFigure = Figure();
densityCFigure = Figure();
densityAxis = Axis(densityFigure[1,1], xlabel="seconds", ylabel="density", title="Submission Density Estimate");
densityCAxis = Axis(densityCFigure[1,1], xlabel="seconds", ylabel="density", title="Correct Submission Density Estimate");
for i in 1:length(avsTasks)
    density!(densityAxis, subsPerTask[i][:,:time], color=:transparent, strokecolor= densityColors[i], strokewidth=2, label=avsTasks[i]);
    density!(densityCAxis, csubsPerTask[i][:,:time], color=:transparent, strokecolor= densityColors[i], strokewidth=2, label=avsTasks[i]);
end
densityElements = [LineElement(color = densityColors[i], linestyle=nothing) for i in 1:length(avsTasks)];
densityFigure[1,2] = Legend(densityFigure, densityElements, avsTasks, "Legend");
densityCFigure[1,2] = Legend(densityCFigure, densityElements, avsTasks, "Legend");
save("plots/avs-submission-density.pdf", densityFigure);
save("plots/avs-submission-correct-density.pdf", densityCFigure);

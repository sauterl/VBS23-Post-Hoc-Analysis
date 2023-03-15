using CSV, DataFrames, CairoMakie, CategoricalArrays, Statistics;
using ColorSchemes, ColorBrewer;

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

# Makie works better with categorical arrays, hence we convert the relevant columns to categorical
df.task = categorical(df.task);
df.team = categorical(df.team);

# Plotting - General setup to be consistent
# Labels: Replacing name to be consistent with output from latex table generation
labels = replace.(levels(df.task), "vbs23-avs" => "a");
# The teams as a vector of unique values
teams = levels(df.team);
# Sampling color scheme. values must be between 0 and 1, hence the division
colors = get(ColorSchemes.cork, collect(0:1/(length(teams)-1):1));
# Elements for the Legend. Basically mapping of colour and labels, hence the same sampling.
elements = [PolyElement(markercolor = i, linecolor = i, polycolor = i) for i in colors[1:length(teams)]];

# Plotting setup
fig = Figure();
# Axis
ax = Axis(fig[1,1],             # Placement within the figure [1,1] is top left
xticks = (                      # The x ticks
    1:length(levels(df.task)),  # Numerical version of xticks, basically indices for label (next argument)
    labels),                    # The labels to draw from (with the indices of the previous argument).
title="Shares of submissions per team and task"
);
# Makie stacked barplot of the shares of submissions per team and task
barplot!(ax,                    # The axis
    df.task.refs,               # The x values, must be numerical, hence the refs. Multiple equal X values result in stacks
    df.ratio,                   # The Y values, must be numerical, this is the share of submissions of a team (bar) for the given task (x tick)
    stack=df.team.refs,         # Numerical value of stack ordering
    color=colors[df.team.refs], # Numerical colour value within the theme (we use the same values as for the stacking)
    #bar_labels=df.team         # Apparently, categorical array works here, basically all the labels for all the bars (remember, they get stacked) # DISABLED, since unreadable
);
# The Legend with reversed entries due to the way of the stacking
Legend(fig[1,2],       # Placement within the figure: to the right of fig[1,1]
    reverse(elements),  # Colour elements aka squares
    reverse(teams),     # The labels, i.e. the teams
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

# Makie works better with categorical arrays, hence we convert the relevant columns to categorical
cdf.task = categorical(cdf.task);
cdf.team = categorical(cdf.team);

# Plotting setup
cfig = Figure();
# Axis
cax = Axis(cfig[1,1],             # Placement within the figure [1,1] is top left
xticks = (                      # The x ticks
1:length(levels(cdf.task)),  # Numerical version of xticks, basically indices for label (next argument)
labels),                    # The labels to draw from (with the indices of the previous argument).
title="Shares of submissions per team and task"
);
# Makie stacked barplot of the shares of submissions per team and task
barplot!(cax,                    # The axis
cdf.task.refs,               # The x values, must be numerical, hence the refs. Multiple equal X values result in stacks
cdf.ratio,                   # The Y values, must be numerical, this is the share of submissions of a team (bar) for the given task (x tick)
stack=cdf.team.refs,         # Numerical value of stack ordering
color=colors[cdf.team.refs], # Numerical colour value within the theme (we use the same values as for the stacking)
#bar_labels=df.team         # Apparently, categorical array works here, basically all the labels for all the bars (remember, they get stacked) # DISABLED, since unreadable
);
# The Legend with reversed entries due to the way of the stacking
Legend(cfig[1,2],       # Placement within the figure: to the right of fig[1,1]
reverse(elements),  # Colour elements aka squares
reverse(teams),     # The labels, i.e. the teams
"Teams"             # Title of the legend
);

# Saving the plot on disk using default size measurements
save("plots/avs-team-ratios-correct.pdf", cfig);

# ---------------------------------------------------
# Analysis of unique submissions
# ---------------------------------------------------
# Group by task and item, count (nrow) and get the unique values on task and item
subsPerTaskItem = unique(combine(groupby(subs, [:task, :item]), :, nrow), [:task, :item]);
# Group by task and segment (item,start,ending), count and get unique values.
subsPerTaskUnique = unique(combine(groupby(subs, [:task, :item, :start, :ending]), :, nrow), [:task, :item, :start, :ending]);

# Get the extrema per task (i.e. max and min per task and unique segments
stats = combine(groupby(subsPerTaskUnique, [:task]), :nrow => (x -> [extrema(x)]) => [:min, :max]);
# join on the task and max to get the segement (item,start,ending) (and do some projection to only have relevant information)
statsWithItem = innerjoin(subsPerTaskUnique, stats, on= [:task => :task, :nrow => :max])[:,[:task, :item, :start, :ending, :status, :nrow]];

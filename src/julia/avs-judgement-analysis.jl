using CSV, DataFrames, CairoMakie, CategoricalArrays
using ColorSchemes, ColorBrewer

juds = DataFrame(CSV.File("data/processed/avs-submissions-judgements.csv"));

# Time between submission and prepare (a judge requested the submission)
juds.deltaPrep = (juds.ptimestamp - juds.stimestamp) ./ 1000; #ms
# Time between prepare and judgement (the time it took the judge)
juds.deltaJudge = (juds.jtimestamp - juds.ptimestamp) ./ 1000;
# Total time it took between submission and verdict
juds.deltaAll = (juds.jtimestamp - juds.stimestamp) ./ 1000;

# Categorise it for Makie
juds.stask = categorical(juds.stask);

fig = Figure();
labels = replace.(levels(juds.stask), "vbs23-avs" => "a");
ax = Axis(fig[1,1],
xticks = ( # x ticks
1:length(levels(juds.stask)), # numerical version of xticks, basically indices for label (next argument)
labels),
title="Time judges took to for their verdict",
xlabel = "tasks",
ylabel = "seconds"
);

# Time between prepare and judgement - the time it took for the judge
boxplot!(ax, juds.stask.refs, juds.deltaJudge);
save("plots/avs-judgement-time-judging.pdf", fig);

# Time between judgement request and deliver (should be small)
fig = Figure();
ax = Axis(fig[1,1],
xticks = ( # x ticks
1:length(levels(juds.stask)), # numerical version of xticks, basically indices for label (next argument)
labels),
title="Time the preparation of a judgement took",
xlabel = "tasks",
ylabel = "seconds"
);
boxplot!(ax, juds.stask.refs, juds.deltaPrep);
save("plots/avs-judgement-time-preparing.pdf", fig);

# Total time between submission and verdict
fig = Figure();
ax = Axis(fig[1,1],
xticks = ( # x ticks
1:length(levels(juds.stask)), # numerical version of xticks, basically indices for label (next argument)
labels),
title="Time between submission and its verdict",
xlabel = "tasks",
ylabel = "seconds"
);
boxplot!(ax, juds.stask.refs, juds.deltaAll);
save("plots/avs-judgement-time-total.pdf", fig);
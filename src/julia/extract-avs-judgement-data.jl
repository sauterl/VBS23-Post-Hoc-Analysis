using JSON3, CSV, DataFrames, JSONTables;

subs = DataFrame(CSV.File("data/processed/avs-submissions.csv"));

# audit log is json-lines

audits = [];

for line in eachline("data/raw/vbs23_audits.json")
    push!(audits, JSON3.read(line));
end

# length of lines aka audits entries
length(audits)

# 1672531200000 is 1.1.2023 in unix epoch ms. this is due to there seems to be old data in the audit log

judgements = filter(e -> e[:type]=="JUDGEMENT" && e[:timestamp] >= 1672531200000 , audits);
prepares = filter(e -> e[:type]=="PREPARE_JUDGEMENT" && e[:timestamp] >= 1672531200000, audits);

judgeSubmDF = DataFrame[]; # judgement - submission table

# with very, very high probability, there would be a innerjoin pure DF way to do this.
for j in judgements
    # Table over judgement | submission on token
    prep = filter(e->e[:token] == j[:token], prepares)[1];
    # submission in judgement prepare
    psub = prep[:submission];
    # dataframe of avassubmission on uid
    subDF = subs[in([psub[:uid][:string]]).(subs.uid),:];

    push!(judgeSubmDF,
    DataFrame(
    jid = j[:id][:string],
    jvalidator = j[:validator],
    token = j[:token],
    verdict = j[:verdict],
    juser = j[:user],
    jtimestamp = j[:timestamp],
    ptimestamp = prep[:timestamp],
    stimestamp = psub[:timestamp],
    pid = prep[:id][:string],
    sid = psub[:uid][:string],
    staskId = subDF[!,:taskId][1];
    stask = subDF[!,:task][1],
    sgroup = subDF[!,:group][1],
    stime = subDF[!,:time][1],
    steam = subDF[!,:team][1],
    smember = subDF[!,:member][1],
    sitem = subDF[!,:item][1],
    sstart = subDF[!,:start][1],
    sending = subDF[!,:ending][1],
    sstatus = subDF[!,:status][1]
    )
    );
end

CSV.write("data/processed/avs-submissions-judgements.csv",vcat(judgeSubmDF...));
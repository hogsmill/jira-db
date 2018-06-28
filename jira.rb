
require 'net/http'
require 'json'

require_relative 'config'
require_relative 'io'
require_relative 'datetime'

$url = $config[:jira][:baseUrl] + "/search?jql=project in (\"" + $config[:jira][:projects].join('", "') + "\") " +
        " AND type in (" + $config[:jira][:types].join(", ") + ") " +
        " AND (resolution in (Complete, Fixed, \"Fixed (Externally)\", Done) OR resolution is EMPTY) " +
        " ORDER BY created ASC&fields=" + $config[:jira][:fields].join(",") +
        "&expand=changelog"

$statuses = []

def getIssues(count)

  batch = "#{$url}&startAt=#{count}"
  uri = URI(batch)
  req = Net::HTTP::Get.new(uri)
  req.basic_auth 'stevew', 'M1sterD00'

  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
    http.request(req)
  }

  issues = JSON.parse(res.body)
  $total = issues["total"]
  issues["issues"]
end

def getCalculatedCycleTime(changelog)

  started = false
  finished = false
  cycleTime = 0
  changelog["histories"].each do |history|
    history["items"].each do |item|
      if (item["field"] == 'status')
        if (!$statuses.include?(item["fromString"]))
          $statuses << item["fromString"]
        end
        if (!$statuses.include?(item["toString"]))
          $statuses << item["toString"]
        end
        if (!started && $config[:jira][:startStates].include?(item["fromString"]))
          started = history["created"]
        end
        if (started && $config[:jira][:endStates].include?(item["toString"]))
          finished = history["created"]
        end
      end
    end
  end

  if (started && finished)
    cycleTime = daysDifference(started, finished)
  end
  cycleTime
end

def getIssue(issue)

  record = {}
  record[:key] = issue["key"]
  record[:summary] = issue["fields"]["summary"].gsub("|", "-")
  record[:created] = issue["fields"]["created"].split("T")[0]
  record[:status] = issue["fields"]["status"]["name"]
  record[:issueType] = issue["fields"]["issuetype"]["name"]
  record[:leadTime] = issue["fields"]["customfield_15201"].to_i
  record[:cycleTime] = issue["fields"]["customfield_15305"].to_i
  resDate = ""
  if (!issue["fields"]["resolutiondate"].nil?)
    record[:resDate] = issue["fields"]["resolutiondate"].split("T")[0]
  end
  resType = ""
  if (!issue["fields"]["resolution"].nil?)
    record[:resType] = issue["fields"]["resolution"]["name"]
  end
  record[:projectKey] = issue["fields"]["project"]["key"]
  record[:projectName] = issue["fields"]["project"]["name"]

  if (record[:cycleTime] == 0)
    record[:cycleTime] = getCalculatedCycleTime(issue["changelog"])
  end

  record
end

$total = 0
issues = getIssues(0)

puts "#{$total} issues, #{issues.length} in batch"

db = dbConnect()
f = getSaveFile()
writeToFile(f, $config[:jira][:headers].join("|"))

results = []
teamResults = {}
count = 0
cycleTime = 0
cycleTimeCount = 0
leadTime = 0

$config[:jira][:projects].each do |team|
  teamResults[team] = {
    :cycleTime => 0,
    :cycleTimeCount => 0,
    :leadTime => 0,
    :leadTimeCount => 0
  }
end

while (count < $total) do
  puts "Starting At #{count}"
  issues = getIssues(count)
  n = issues.length
  for i in 0..n-1 do
    record = getIssue(issues[i])
    if (record[:cycleTime] > 0)
      cycleTime = cycleTime + record[:cycleTime]
      cycleTimeCount = cycleTimeCount + 1
      teamResults[record[:projectName]][:cycleTime] = teamResults[record[:projectName]][:cycleTime] + record[:cycleTime]
      teamResults[record[:projectName]][:cycleTimeCount] = teamResults[record[:projectName]][:cycleTimeCount] + 1
    end
    leadTime = leadTime + record[:leadTime]
    teamResults[record[:projectName]][:leadTime] = teamResults[record[:projectName]][:leadTime] + record[:leadTime]
    teamResults[record[:projectName]][:leadTimeCount] = teamResults[record[:projectName]][:leadTimeCount] + 1

    writIssueToFile(f, record)
    writeIssueToDb(db, record)
  end
  count = count + n
end

writeStatsToDb(db, cycleTime, cycleTimeCount, leadTime, count)

$config[:jira][:projects].each do |team|
  writeTeamStatsToDb(db, team,
    teamResults[team][:cycleTime],
    teamResults[team][:cycleTimeCount],
    teamResults[team][:leadTime],
    teamResults[team][:leadTimeCount]
  )
end

puts "Cycle Time: #{cycleTime} (#{cycleTimeCount}), Lead Time: #{leadTime} (#{count})"
puts $statuses.inspect

f.close()


require 'mongo'

require_relative 'config'

def dbConnect
  client = Mongo::Client.new([ "#{$config[:mongo][:ip]}:#{$config[:mongo][:port]}" ],
    :database => $config[:mongo][:database])
  client
end

def writeIssueToDb(db, issue)
  issue[:queryDate] = Date.today().strftime("%Y-%m-%d")

  issues = db[:issues]
  issues.delete_many({:key => issue[:key], :queryDate => issue[:queryDate]})
  issues.insert_one(issue)
end

def writeStatsToDb(db, cycleTime, cycleTimeCount, leadTime, leadTimeCount)
  summary = {}
  summary[:date] = Date.today().strftime("%Y-%m-%d")
  summary[:cycleTime] = cycleTime / cycleTimeCount
  summary[:leadTime] = leadTime / leadTimeCount

  summaries = db[:summary]
  summaries.delete_many({:date => summary[:date]})
  summaries.insert_one(summary)
end

def writeTeamStatsToDb(db, team, cycleTime, cycleTimeCount, leadTime, leadTimeCount)
  summary = {}
  summary[:team] = team
  summary[:date] = Date.today().strftime("%Y-%m-%d")
  summary[:cycleTime] = cycleTimeCount == 0 ? 0 : cycleTime / cycleTimeCount
  summary[:leadTime] = leadTimeCount == 0 ? 0 : leadTime / leadTimeCount

  summaries = db[:teamsummaries]
  summaries.delete_many({:date => summary[:date], :team => team})
  summaries.insert_one(summary)
end

def getSaveFile

  resultsFile = File.dirname(Dir.pwd) + '/' + File.basename(Dir.getwd) + '/tmp.csv'
  File.delete(resultsFile)
  f = File.open(resultsFile, 'a')

end

def writeToFile(f, s)

  f.write(s + "\n")
end

def writIssueToFile(f, issue)

  record = [
    issue[:key], issue[:summary], issue[:resDate], issue[:status], issue[:issueType],
    issue[:leadTime], issue[:cycleTime], issue[:resType]].join("|")

  writeToFile(f, record)
end

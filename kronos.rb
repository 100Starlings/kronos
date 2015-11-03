require "rubygems"
require "bundler"
require "json"
require "csv"
Bundler.require(:default)
Dotenv.load

$LOAD_PATH.unshift "lib"
require "kronos"

fa = Kronos::Freeagent.new

### Timeslips
timeslips_from = "2015-05-01"
timeslips_to = "2015-05-31"

timeslips = fa.timeslips(timeslips_from, timeslips_to)

### Jira

jira_client = Kronos::Jira.new(
  username: ENV["JIRA_USERNAME"],
  password: ENV["JIRA_PASSWORD"])

issues_with_capex = jira_client
  .issues_with_capex
  .each_with_object({}) do |i, h|
    h[i.key] = i.fields[ENV["JIRA_CAPEX_FIELD"]]
  end

capex_numbers = issues_with_capex.values.compact.uniq

### Capexed timeslips
issue_key_regex = /(#{ENV["JIRA_PROJECT_PREFIX"]}-\d+)/
tasks = {}
users = {}
CSV.open("timeslips.csv", "w+") do |csv|
  csv << %w(capex story hours date name task comment)
  timeslips.each do |t|
    name = users[t.user] || begin
      response = fa.client.get(t.user)
      user_json = JSON.parse(response.body)
      user = Hashie::Mash.new(user_json["user"])
      users[t.user] = "#{user.first_name} #{user.last_name}"
    end

    task = tasks[t.task] || begin
      response = fa.client.get(t.task)
      task_json = JSON.parse(response.body)
      task = Hashie::Mash.new(task_json["task"])
      tasks[t.task] = task.name
    end

    hours = t.hours
    comment = t.comment
    capex = ""
    story = ""

    if comment
      capexes = capex_numbers.select { |cx| comment.match cx }
      issue_keys = comment.match(issue_key_regex)
      issue_keys &&= issue_keys.captures
      issue_keys ||= []
      issue_keys.each do |k|
        capexes.push(issues_with_capex[k])
        story_time = t.hours.to_f / issue_keys.size
        jira_client.add_timeslip(k, story_time, date)
      end
      capex = capexes.join(" ")
      story = issue_keys.join(" ")

    end
    csv << [capex, story, hours, date, name, task, t.comment]
  end
end

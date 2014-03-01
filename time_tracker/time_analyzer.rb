require_relative './mongo'
# require 'mongo'

module Time_Analyzer
	# include Mongo


	def self.controller

		Mongo_Connection.mongo_Connect("localhost", 27017, "GitHub-TimeTracking", "TimeTrackingCommits")

	end


	def self.analyze_issue_spent_hours
		totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
			{"$project" => {type: 1, 
							issue_number: 1, 
							_id: 1, 
							repo: 1,
							milestone_number: 1, 
							issue_state: 1, 
							issue_title: 1, 
							time_tracking_commits:{ duration: 1, 
													type: 1, 
													comment_id: 1 }}},			
			{ "$match" => { type: "Issue" }},
			{ "$unwind" => "$time_tracking_commits" },
			{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Time"] }}},
			{ "$group" => { _id: {
							repo_name: "$repo",
							milestone_number: "$milestone_number",
							issue_number: "$issue_number",
							issue_title: "$issue_title",
							issue_state: "$issue_state", },
							time_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
							time_comment_count: { "$sum" => 1 }
							}}
							])
		output = []
		totalIssueSpentHoursBreakdown.each do |x|
			x["_id"]["time_duration_sum"] = x["time_duration_sum"]
			x["_id"]["time_comment_count"] = x["time_comment_count"]
			output << x["_id"]
		end
		return output
	end

	def self.analyze_issue_budget_hours
		totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
			{"$project" => {type: 1, 
							issue_number: 1, 
							_id: 1, 
							repo: 1,
							milestone_number: 1, 
							issue_state: 1, 
							issue_title: 1, 
							time_tracking_commits:{ duration: 1, 
													type: 1, 
													comment_id: 1 }}},			
			{ "$match" => { type: "Issue" }},
			{ "$unwind" => "$time_tracking_commits" },
			{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Budget"] }}},
			{ "$group" => { _id: {
							repo_name: "$repo",
							milestone_number: "$milestone_number",
							issue_number: "$issue_number",
							issue_state: "$issue_state",
							issue_title: "$issue_title",},
							budget_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
							budget_comment_count: { "$sum" => 1 }
							}}
							])
		output = []
		totalIssueSpentHoursBreakdown.each do |x|
			x["_id"]["budget_duration_sum"] = x["budget_duration_sum"]
			x["_id"]["budget_comment_count"] = x["budget_comment_count"]
			output << x["_id"]
		end
		return output
	end


	def self.merge_issue_time_and_budget(issuesTime, issuesBudget)

		issuesTime.each do |t|

			issuesBudget.each do |b|

				if b["issue_number"] == t["issue_number"]
					t["budget_duration_sum"] = b["budget_duration_sum"]
					t["budget_comment_count"] = b["budget_comment_count"]
					break
				end					
			end
			if t.has_key?("budget_duration_sum") == false and t.has_key?("budget_comment_count") == false
				t["budget_duration_sum"] = nil
				t["budget_comment_count"] = nil
			end
		end

		return issuesTime
	end

	def self.analyze_milestones
		totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
			{"$project" => {type: 1, 
							milestone_number: 1, 
							_id: 1, 
							repo: 1,
							milestone_state: 1, 
							milestone_title: 1, 
							milestone_open_issue_count: 1,
							milestone_closed_issue_count: 1,
							budget_tracking_commits:{ duration: 1, 
													type: 1}}},			
			{ "$match" => { type: "Milestone" }},
			{ "$unwind" => "$budget_tracking_commits" },
			{ "$match" => { "budget_tracking_commits.type" => { "$in" => ["Milestone Budget"] }}},
			{ "$group" => { _id: {
							repo_name: "$repo",
							milestone_number: "$milestone_number",
							milestone_state: "$milestone_state",
							milestone_title: "$milestone_title",
							milestone_open_issue_count: "$milestone_open_issue_count",
							milestone_closed_issue_count: "$milestone_closed_issue_count",},
							milestone_duration_sum: { "$sum" => "$budget_tracking_commits.duration" }
							}}
							])
		output = []
		totalIssueSpentHoursBreakdown.each do |x|
			x["_id"]["milestone_duration_sum"] = x["milestone_duration_sum"]
			output << x["_id"]
		end
		return output
	end


	# gets time per user for each issue
	def self.analyze_issue_spent_hours_per_user(repo, issueNumber)

		totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
			{"$project" => {type: 1, 
							issue_number: 1, 
							_id: 1, 
							repo: 1,
							time_tracking_commits:{ duration: 1, 
													type: 1,
													work_logged_by: 1}}},			
			{ "$match" => { type: "Issue", repo: repo, issue_number: issueNumber }},
			{ "$unwind" => "$time_tracking_commits" },
			{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Time"] }}},
			{ "$group" => { _id: {
							repo_name: "$repo",
							issue_number: "$issue_number",
							work_logged_by: "$time_tracking_commits.work_logged_by"},
							time_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
							time_comment_count: { "$sum" => 1 }
							}},
							])
		output = []
		totalIssueSpentHoursBreakdown.each do |x|
			x["_id"]["time_duration_sum"] = x["time_duration_sum"]
			x["_id"]["time_comment_count"] = x["time_comment_count"]
			output << x["_id"]
		end
		return output
	end




	# gets the issues and the spent hours for a specific milestone
	# argument input is a array of integers: 1 or more, representing milestone numbers
	def self.analyze_issue_spent_hours_per_milestone(milestoneNumber)
		totalIssueSpentHoursBreakdown = Mongo_Connection.aggregate_test([
			{"$project" => {type: 1, 
							issue_number: 1, 
							_id: 1, 
							repo: 1,
							milestone_number: 1, 
							issue_state: 1, 
							issue_title: 1, 
							time_tracking_commits:{ duration: 1, 
													type: 1, 
													comment_id: 1 }}},			
			{ "$match" => { type: "Issue", milestone_number: milestoneNumber }},
			{ "$unwind" => "$time_tracking_commits" },
			{ "$match" => { "time_tracking_commits.type" => { "$in" => ["Issue Time"] }}},
			{ "$group" => { _id: {
							repo_name: "$repo",
							milestone_number: "$milestone_number",
							issue_number: "$issue_number",
							issue_title: "$issue_title",
							issue_state: "$issue_state", },
							time_duration_sum: { "$sum" => "$time_tracking_commits.duration" },
							time_comment_count: { "$sum" => 1 }
							}}
							])
		output = []
		totalIssueSpentHoursBreakdown.each do |x|
			x["_id"]["time_duration_sum"] = x["time_duration_sum"]
			x["_id"]["time_comment_count"] = x["time_comment_count"]
			output << x["_id"]
		end
		return output
	end





end

# Time_Analyzer.controller

# puts Time_Analyzer.analyze_issue_spent_hours_per_user
# puts Time_Analyzer.analyze_issue_spent_hours_per_milestone(1)


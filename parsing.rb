require "json"
require "ap"

file = open("pegasus_527.json")
file = file.read

parsed = JSON.parse(file)

acc_up = []
acc_downs = []
parsed["data"]["children"].each do |child|
	data_node = []
	data_hash = child["data"]
	if data_hash["title"] == nil
		data_node << data_hash["body"]
	else
		data_node << data_hash["title"]
	end

	data_node << data_hash["ups"]
	acc_up << data_node.dup

	#Take away the upvote string
	data_node.pop

	#... And add the downvote string
	data_node << data_hash["downs"]

	acc_downs << data_node
	data_node = []
end

#Make it chronological
acc_up.reverse!
acc_downs.reverse!

p acc_up
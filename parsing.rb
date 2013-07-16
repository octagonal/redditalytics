require "json"
require "ap"

file = open("pegasus_527.json")
file = file.read

parsed = JSON.parse(file)

acc_up = []
acc_downs = []
parsed["data"]["children"].each do |child|
	temp_array = []
	if child["data"]["title"] == nil
		temp_array << child["data"]["body"]
	else
		temp_array << child["data"]["title"]
	end

	#p child["data"]["ups"]

	temp_array << child["data"]["ups"]
	acc_up << temp_array.dup

	temp_array.pop

	temp_array << child["data"]["downs"]
	acc_downs << temp_array
	temp_array = []
end

acc_up.reverse!
acc_downs.reverse!
p acc_up
puts "\n"
p acc_downs
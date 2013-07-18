require 'ap'
require 'rest-client'
require 'json'

class Redditor
	@@base_url = "http://www.reddit.com/"
	@@user_agent = "Redditalytics alpha [/u/pegasus_527, github/octagonal/redditalytics]"
	attr_reader :user, :sort, :limit, :type, :results

	def initialize(user,sort,limit,type)
		@user = user
		@sort = sort
		@limit = limit
		@type = type
	end

	def results
		@results ||= parse_json
	end

	def parse_json
		file = form_url
		file = get_url(file)
		file = get_json(file)

		acc_up = []
		acc_downs = []
		file["data"]["children"].each do |child|
			data_node = []
			data_hash = child["data"]
			case @type
			when "comment"
				data_node << data_hash["body"]
			when "link"
				data_node << data_hash["title"]
			when "both"
				if data_hash["title"] == nil
					data_node << data_hash["body"]
				else
					data_node << data_hash["title"]
				end
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
		acc_downs.map! { |node|
		collect = node[0],node[1]*-1
		collect
		}

		[acc_up,acc_downs]
	end

	private
	def form_url
		file_type = ".json"
		formed_url = ""

		formed_url << @@base_url
		formed_url << "/user/#{@user}/"

		case @type
		when "comment"
			formed_url << "comments"
		when "link"
			formed_url << "submitted"
		when "both"
			formed_url << "overview"
		end

		formed_url << file_type
		formed_url
	end

	def get_url(url)
		file = RestClient.get url, {:params => {:sort => @sort, :limit => @limit, :user_agent => @@user_agent}}
		file
	end

	def get_json(file)
		parsed = JSON.parse(file)
		parsed
	end
end

=begin

→ /user/username/overview
→ /user/username/submitted
→ /user/username/comments
→ /user/username/liked
→ /user/username/disliked
→ /user/username/hidden
→ /user/username/saved

=end
require 'rest-client'
require 'sinatra'
require "json"
require "ap"

get '/' do
	'Hello World'
end

get '/:user' do
	@ups = get_votes(params[:user])[0]
	@downs = get_votes(params[:user])[1]
	@user = params[:user]
	erb :index
end

def get_votes(user)
	base_url = "http://www.reddit.com/user/"
	append = "/comments.json"
	url = base_url + user + append
	puts url
	file = RestClient.get url, {:params => {:sort => :top, :limit => 100, :user_agent => "Redditalytics alpha [/u/pegasus_527, github/octagonal/redditalytics]"}}

	parsed = JSON.parse(file)

	acc_up = []
	acc_downs = []
	parsed["data"]["children"].each do |child|
		data_node = []
		data_hash = child["data"]
		if data_hash["title"] == nil
			data_node << data_hash["body"]
		else
			#data_node << data_hash["title"]
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
	p acc_downs

	[acc_up,acc_downs]
end
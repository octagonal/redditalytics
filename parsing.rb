require 'rest-client'
require 'sinatra'
require "json"
require "ap"

#Set global variables for view
configure do
  Sort = OpenStruct.new(
    :hot => 'value="hot" id="hot"',
    :newsort => 'value="new" id="new"',
    :top => 'value="top" id="top"',
    :controversial => 'value="controversial" id="controversial"'
  )
  Type = OpenStruct.new(
    :submitted => 'value="submitted" id="submitted"',
    :comments => 'value="comments" id="submitted"',
    :overview => 'value="overview" id="overview"'
  )
end

get '/' do
	erb :post
end

post '/' do
	sort = "sort="
	sort << params[:sort]
	limit = "limit="
	limit << params[:limit]

	#All queries lead to the Reddit routing style now
	redirect to("/user/#{params[:user]}/#{params[:type]}/?#{sort}&#{limit}")
end

#This is mainly a convenience route so users can simply replace reddit.com by redditalytics.com to get to a graph
get '/user/:user/' do
	sort = "sort="
	if params[:sort]
		sort << params[:sort]
	else
		sort << "new"
	end
	redirect to("/user/#{params[:user]}/overview/?#{sort}")
end

#This route is analogous to how Reddit routes pages
get '/user/:user/:type/' do
	limit = 100
	if params[:limit]
		limit = params[:limit]
	end

	sort = "new"
	if params[:sort]
		sort = params[:sort]
	end

	user = Redditor.new(params[:user],params[:type],sort,limit)

	@ups = user.results[0]
	@downs = user.results[1]

	@sort_pretty = user.sort_pretty
	@sort = user.sort

	@limit = user.limit
	@user = params[:user]

	@type_pretty = user.type_pretty
	@type = user.type

	erb :index
end

class Redditor
	@@base_url = "http://www.reddit.com/"
	@@user_agent = "Redditalytics alpha [/u/pegasus_527, github/octagonal/redditalytics]"
	attr_reader :user, :sort, :limit, :type, :results
	attr_reader :sort_pretty, :type_pretty

	def initialize(user,type,sort,limit=100)
		@user = user
		@sort = sort
		@limit = limit
		@type = type
		beautify
		puts "#{user}#{sort_pretty}#{limit}#{type_pretty}"
	end

	def beautify
		case @type
		when "comments"
			@type_pretty = "comments"
		when "submitted"
			@type_pretty = "submissions"
		when "overview"
			@type_pretty = "links and comments"
		end

		case @sort
		when "hot"
			@sort_pretty = "hottest"
		when "new"
			@sort_pretty = "newest"
		when "top"
			@sort_pretty = "top"
		when "controversial"
			@sort_pretty = "most controversial"
		end
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
			when "comments"
				data_node << data_hash["body"]
			when "submitted"
				data_node << data_hash["title"]
			when "overview"
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
		when "comments"
			formed_url << "comments"
		when "submitted"
			formed_url << "submitted"
		when "overview"
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
require 'rest-client'
require 'sinatra'
require "json"
require "ap"

#Set global variables
configure do
  Sort = OpenStruct.new(
    :hot => 'hot',
    :newsort => 'new',
    :top => 'top',
    :controversial => 'controversial'
  )
  Type = OpenStruct.new(
    :submitted => 'submitted',
    :comments => 'comments',
    :overview => 'overview'
  )
end

get '/' do
	erb :post
end

get '/:user' do
	user = Redditor.new(params[:user],"new",10,"comment")
	@ups = user.results[0]
	@downs = user.results[1]
	@user = params[:user]
	erb :index
end

post '/' do
	sort = "sort="
	sort << params[:sort]
	limit = "limit="
	limit << params[:limit]

	redirect to("/user/#{params[:user]}/#{params[:type]}/?#{sort}&#{limit}")
end

get '/test/:user/:type/' do
	sort = "?sort="
	sort << params[:sort]
	redirect to("/user/#{params[:user]}/#{params[:type]}/#{sort}")
end

get '/user/:user' do
	redirect to("/user/#{params[:user]}/overview/?sort=new")
end

#This route is analogous to how Reddit routes pages
get '/user/:user/:type/' do
	#Set initial values, override if any custom ones are given
	limit = 100
	if params[:limit]
		limit = params[:limit]
	end

	sort = "new"
	if params[:sort]
		sort = params[:sort]
	end

	user = Redditor.new(params[:user],params[:type],params[:sort],limit)

	@ups = user.results[0]
	@downs = user.results[1]
	@sort = user.sort
	@limit = user.limit
	if user.type == "overview"
		@type = "submission"
	else
		@type = user.type
	end
	@user = params[:user]

	erb :index
end

class Redditor
	@@base_url = "http://www.reddit.com/"
	@@user_agent = "Redditalytics alpha [/u/pegasus_527, github/octagonal/redditalytics]"
	attr_reader :user, :sort, :limit, :type, :results

	# sort 	=> hot, new, top, controversial
	# limit => 0..100
	# type 	=> submitted, comments, overview (all
	# user 	=> String
	def initialize(user,type,sort,limit=100)
		@user = user
		@sort = sort
		@limit = limit
		@type = type
		puts "#{user}#{sort}#{limit}#{type}"
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

		ap acc_up

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
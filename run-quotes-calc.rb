require 'sequel'
require 'nokogiri'

require_relative  'helper'
require_relative  'repo'

DB = Repo.get_conn

from = DateTime.now.to_date

posts = DB[:posts].filter('addeddate > ? and addeddate < ?',from,from +1).all

#posts = DB[:posts].filter(:tid=>1128175).all
p posts.size

users = DB[:users].to_hash(:username, :uid)
tusers = users.keys
act ='show athor quote'
  
if act=='show athor quote' 
	count=0
	posts.each do |post|
			text = post[:text].strip
			quoted = Helper.detect_quote_to(text,[]) 
			p post[:mid] if quoted=="автор"
	end
	p count
end


if act=='calc quote' 
	DB.transaction do

		posts.each do |post|
			#p post[:text]
			text = post[:text].strip

			quoted = Helper.detect_quote_to(text,tusers) 
	      quote_userid = users[quoted] if quoted != post[:addedby]

			DB[:posts].filter(:mid=> post[:mid]).update(:quote_user => quote_userid) 
			
		end

	end
end
require 'sequel'
require_relative  'repo'

DB = Repo.get_conn

from = DateTime.now.to_date

posts = DB[:posts].filter('addeddate > ? and addeddate < ?',from,from +1).select(:addeduid, :quote_user).all
#posts = DB[:posts].filter(:tid=>1128175).select(:addeduid, :quote_user).all
p posts.size

users = DB[:users].to_hash(:uid, :username)


data= posts.group_by{ |p| p[:quote_user] }.map{|k,v| [users[k], v.size]}.sort_by { |it| -it[1] }

p data


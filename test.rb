require 'sequel'
require_relative  'helper'
require_relative  'repo'

DB = Sequel.connect(YAML.load(File.open('database.yml')))

tid =1121772
pg =1
a=3

if a==1
  max= db[:tpages].where('tid=? and postCount = 25',tid).select{max(page)}.first[:max]
  max = 0 if max.nil?
  p max

  found = db[:tpages].where('tid=? and page=?',tid, pg).first
  max =  if found.nil? then 0 else found[:postcount] end
  p max
end

if a==2
  from = DateTime.now - (24/24.0)

  posts = db[:posts].filter('addeddate > ?',from)
  .order(:addeddate)
  .select(:addeduid, :addedby, :addeddate).all

  posts.each do |p|
    puts p[:addeddate]
  end

end

page_threads = ForumLoader.get_threads(1)
puts page_threads.map { |thr| [thr.tid, thr.updated] }

#p pages_map = Repo.get_thread_page_count(tid)

#Repo.log_running("parse_forum_page [page=1]")

#user_posts =  Repo.find_users_since_last_running

#p user_posts.group_by{|h| h[:addedby]}.sort_by{ |k,v| -v.size }.map{|k,v| [k, v.size]}

#p pages_map.select{|k,v| v!=25}

#p Repo.find_last_25page(tid)
#p max =  DB[:tpages].where('tid=? and postCount = 25',1131953).select{max(page)}.first[:max]

# select tid,page, count(page) from tpages group by tid , page  having count(page) =1

#Repo.create_new_pages(106,1131953)

#Repo.update_pages_table(28,1135526,'a')

#ConReport.show_users_after_downloading

#ConReport.recent_users 16

#ConReport.show_user_posts_from(214716, 5)

#system "cd '/home/kilk/SpiderOak Hive/ptbot'; ruby run.rb"

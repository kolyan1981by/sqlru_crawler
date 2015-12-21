require_relative  'report'
require_relative  'user_parser'

uid = 152436

s=5

if s == 4
    username = Repo.get_username(uid)
    p username
    UserParser.search_user_posts(username,1,10)
end

if s == 5
    p username = Repo.get_username(uid).gsub(" ", "_")
    path = File.dirname(__FILE__) + "/generated/posts_#{username}_#{uid}.html"
    Report.gen_user_posts(uid, path)
end

require_relative  'report'

s =1

if s ==1
    path =File.dirname(__FILE__) + "/generated/last20.html"
    Report.show_recent_posts(path,60)
end

if s== 7
    path =File.dirname(__FILE__) + "/generated/last_users.html"
    Report.show_recent_users(path,120)
end

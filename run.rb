require 'parallel'
require_relative  'forum_parser'
require_relative  'repo'
require_relative  'report'
require_relative  'report_console'

require_relative  'helper_erb'

p "args #{ARGV}"


def info
  p "pt info (show info)"
  p "pt 1 (download only 1 page)"
  p "pt rt (from to | from) (show recent thread and post)"
  p "pt p (user_id , hours back :def=8)(show user posts for 8 last hours)"
  p "pt ru (hours back :def=8)(show recent users)"
  p "pt log h --- show last running bot actions"
  p "pt last --- show  website user logs"
  p "pt loadt tid --- load thread by tid"
  p "----------"
end

last_running_date = Repo.find_last_running_date

if ARGV[0] == 'info'
  info

elsif ARGV[0] == 'rt'
  path =File.dirname(__FILE__) + "/generated/last20.html"
  hours_back_start = ARGV[1].to_i
  hours_back_end = ARGV[2].to_i

  #pt rt 3 2
  ConReport.show_recent_threads_with_posts(hours_back_start, hours_back_end)

elsif ARGV[0] == 'ru'
  path =File.dirname(__FILE__) + "/generated/last_users.html"
  hours_back = ARGV[1].to_i
  #Report.show_recent_users(path, hours_back==0?10:hours_back)

  ConReport.show_recent_users(hours_back)

elsif ARGV[0] == 'p'
  uid = ARGV[1].to_i
  hours = ARGV[2].to_i
  ConReport.show_user_posts_from(uid, hours)

elsif ARGV[0] == 'log'
  p "log"
  ConReport.show_today_botlogs ARGV[1].to_i

elsif ARGV[0] == 'last'
  ConReport.show_today_weblogs

elsif ARGV[0] == 'loadt'
    url = "http://www.sql.ru/forum/#{ARGV[1].to_i}/"
    ThreadParser.load_thread(url)
else

  first = ARGV[0].to_i
  first =1 if first==0

  last = ARGV[1].to_i
  if last==0 then last =first; first=1 end

  p "#{first} #{last}"
  for p in first..last
    ForumParser.parse_subforum_page(p)
  end
  ConReport.show_users_after_downloading(last_running_date)
  Repo.log_running("run [pages:#{last}]")

end
p "last running = #{last_running_date}"

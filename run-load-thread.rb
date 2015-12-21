require_relative  'report'
require_relative  'thread_parser'


s=2

if s== 2

    url = "http://www.sql.ru/forum/1137720/"
    ThreadParser.load_thread(url)
end

if s== 21
    tid = 1126980
    Repo.del_thread(tid)
end

if s== 3
    tid = 1120610
    path = "/home/kilk/work/ruby/ffbot/app_data/generated/thread_#{tid}.html"
    Report.gen_all_pages_thread(tid,path)
end

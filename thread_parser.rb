require_relative  'models'
require_relative  'forum_parser'
require_relative  'thread_parser'
require_relative  'repo'
require_relative  'helper'
require 'parallel'

module ThreadParser

   def self.check_db_get_post(url, site_resp_count)

    tid, pg = Helper.get_tid_pg(url)
    pg = (site_resp_count)/25+1  if pg == "a"

    db_count = Repo.page_posts_count(tid, pg)
    site_last_count = (site_resp_count + 1) % 25

    return nil if db_count == 25
    return nil if db_count == site_last_count

    ThreadLoader.load_posts(url)

  end


  def self.load_thread(url)

   
    tid, pg = Helper.get_tid_pg(url)

    save_thread_if_exist(url, tid)

    max_page = ThreadLoader.get_max_page(url)
    max_page = 1 if max_page.nil?

    urls=[]

    max_page.downto(1).each do |p|
      u = Url.new
      u.href = "http://www.sql.ru/forum/#{tid}-#{p}" + Helper.get_thread_title(url)
      urls << u
    end

    results = Parallel.map_with_index(urls,:in_threads=>7) do |page_url, ind|
    #urls.each_with_index do |page_url, ind|

      tid, pg = Helper.get_tid_pg(page_url.href)
      count = Repo.page_posts_count(tid, pg)
      if count != 25
        ThreadLoader.load_posts(page_url.href)
        p "#{ind} loaded #{page_url.href}"
      else
        p "#{ind} exist #{page_url.href}"
      end
    end

    p "finished"
  end
  
  def self.save_thread_if_exist(url, tid)
    th = FThread.new

    th.fid = 16
    th.tid = tid.to_i
    th.title = Helper.get_thread_title(url)
    th.title[0] = ''

    th.responses = 0
    th.viewers = 0

    Repo.update_or_save_threads([th])
  end

end






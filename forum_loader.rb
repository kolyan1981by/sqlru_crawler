

require 'nokogiri'
require 'open-uri'

require_relative  'models'
require_relative  'helper'

class ForumLoader
  def load_forums
    #page = Nokogiri::HTML(open("http://www.sql.ru/forum"),nil,ENCODING)
    #nodes =  page.css("table.forumTable tr td a.forumLink")
    #nodes.each{|t| puts "-----"; puts t.text }
  end

  def self.get_threads(fpg=1, fname = 'pt')

    fid = Helper.get_forum_id(fname)

    furl = "http://www.sql.ru/forum/pt" + (fpg >1 ? "/#{fpg}" : "")

    page = Helper.download_page(furl)

    thread_rows =  page.css("table.forumTable tr")
    res=[]

    thread_rows.drop(1).each do |t|

      url = t.css("td.postslisttopic a")[0]['href']

      tid, pg = Helper.get_tid_pg(url)
      #next if tid != '1131953'

      urls = parse_page_urls(t.css("td.postslisttopic span a"),url ,tid)

      th = FThread.new

      th.fid = fid
      th.tid = tid.to_i
      th.title = t.css("td.postslisttopic a")[0].text
      th.pages = urls
      th.responses = t.css("td")[3].text.to_i
      th.viewers = t.css("td")[4].text.to_i
      th.updated = Helper.parse_rudate(t.css("td")[5].text)

      res<< th

    end

    res
  end

  def self.parse_page_urls(span_urls, url, tid)
    last_db_25page = Repo.find_last_25page(tid)


    max_page = span_urls.map{|u| u.text.to_i}.max

    return [] if !max_page.nil? && max_page > 500

    res = []

    all = span_urls.find {|u| u.text == "все" }

    if all.nil? || ( max_page - last_db_25page <= 1 )

      if max_page.nil?
        u2 = Url.new
        u2.href = url
        res << u2

      else

        max_page.downto(1).each do |p|
          u2 = Url.new
          u2.href = "http://www.sql.ru/forum/#{tid}-#{p}" + Helper.get_thread_title(url)
          res << u2
        end

      end

    else
      u = Url.new
      u.text = all.text
      u.href = all['href']
      res << u
    end

    res
  end

end

require 'sqlite3'
require 'uri'
require_relative  'report'
require_relative  'repo'
require_relative  'thread_loader'
require 'parallel'
 
module UserParser
  SEARCH_URL = "http://www.sql.ru/forum/actualsearch.aspx?a={0}&ma=1"
  
def self.search_user_posts(username, first, last)
  
 
  need_load = true
  
  encoded_username = URI.escape username.encode("windows-1251")
  base_url = "http://www.sql.ru/forum/actualsearch.aspx?a=#{encoded_username}&ma=1"
  
  for p in first..last
    url = base_url
    url = url + "&pg=#{p}" if p>1
    p url
    
    page_htm = Helper.download_page(url)
    #save_to_file(page_htm)
    thread_rows =  page_htm.css("table.forumTable")[0].css("tr")
    
    thrs=[]
   
    thread_rows.drop(1).each do |t|
     
      #next if t.css("td.postslisttopic a")[0].nil?
      
      url = t.css("td.postslisttopic a")[0]['href']
      
      tid, pg = Helper.get_tid_pg(url)
      urls = extract_thread_urls(t.css("td.postslisttopic span a"), url)
      fname = t.css("td")[2].css("a")[0]['href'].gsub(/http:\/\/www.sql.ru\/forum\//, '')
      #p urls[0].href if urls.any?
      
      th = FThread.new

      th.fid = Helper.get_forum_id(fname.strip)
      th.forumname = fname
      th.tid = tid.to_i
      th.title = t.css("td.postslisttopic a")[0].text
      th.pages = urls
      th.responses = t.css("td")[4].text.to_i
      th.viewers = t.css("td")[5].text.to_i
      
      thrs<< th
      
    end
    
    Repo.update_or_save_threads(thrs) if need_load
    load_threads_on_page_par(thrs) if need_load
    
    puts "finished"
  end 
end
def self.save_to_file(page_htm)
   path = "/tmp/11.html"
     File.open(path, 'w') do |file|
      file.puts page_htm
    end

    system "firefox "+ path
end

def self.load_threads_on_page(threads)
  threads.each do |thr|
    next if thr.pages.empty?
    
    url =thr.pages[0].href
    tid, pg = Helper.get_tid_pg(url)
    
    posts = ThreadLoader.check_db_get_post(url, thr.responses) #ThreadParser.load_posts(url) 
    
    if posts.nil?
      p  "exist #{tid}-#{pg}"
    else
      count = posts.size
      p "saved #{tid}-#{pg} count=#{count}"
    end  
    
  end
end

def self.load_threads_on_page_par(threads)
  results = Parallel.map_with_index(threads,:in_threads=>5) do |thr, ind|
    next if thr.pages.empty?
    url =thr.pages[0].href
    tid, pg = Helper.get_tid_pg(url)

    posts = ThreadLoader.check_db_get_post(url, thr.responses)
    if posts.nil?
      p  "exist #{tid}-#{pg}"
    else
      count = posts.size
      p "saved #{tid}-#{pg} count=#{count}"
    end  
    
  end
end

def self.extract_thread_urls(span_urls, url)

    max_page = span_urls.map{|u| u.text.to_i}.max

    res = []

    all = span_urls.find {|u| u.text == "все" }

    if !all.nil?
      u = Url.new
      u.text = all.text
      u.href = all['href'].gsub(/\?hl=/, '')
      res << u
    elsif all.nil? && max_page.nil? 
      u = Url.new
      u.text = Helper.get_thread_title(url)
      u.href = url.gsub(/\?hl=/, '')
      res << u if !u.href.nil?
    end

    res
end
end




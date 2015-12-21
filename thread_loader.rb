require 'nokogiri'
require 'open-uri'

require_relative  'models'
require_relative  'forum_parser'
require_relative  'helper'

module ThreadLoader
 
  def self.load_posts(url)
    page = Helper.download_page(url)
    site_posts =  page.css("table.msgTable")
    res=[]

    site_posts.each do |p|
      begin
        
        post = Post.new
        
        if p.css("tr td.msgBody:first a").empty?
          post.addedname = p.css("tr td.msgBody:first").text.gsub(/\r\n/, "").strip
          post.addeduid = -1
        else
          post.addedname =  p.css("tr td.msgBody:first a")[0].text.strip  
          post.addeduid =  p.css("tr td.msgBody:first a")[0]['href'].gsub(/\D/, "").to_i
        end
        post.text = p.css("tr td.msgBody:last").inner_html.strip
        post.mid = p.css("tr:last td.msgFooter a")[0].text.to_i
        date = p.css("tr:last td.msgFooter > text()").text.gsub('[]', '').gsub('|', '').strip
        post.addeddate = parse_post_time(date)
  
        res<<post
      rescue
        puts "error #{url}"
      end
    end
    tid, pg = Helper.get_tid_pg(url)
    Repo.save_posts(res, tid, pg)

    res
  end


  def self.parse_post_time(tm)
    return Helper.parse_rudate(tm)
  end

  def self.get_max_page(url)
    page = Helper.download_page(url)
    urls =  page.css("table.sort_options a")
    max_page = urls.map{|u| u.text.to_i}.max
  end
end

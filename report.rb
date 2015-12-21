require 'sequel'

require_relative  'helper'
require_relative  'repo'
class Report

    @@DB = Repo.get_conn
    def self.gen_user_posts(uid,path)

      posts = @@DB[:posts].filter(:addeduid => uid).order(:addeddate)
      .extension(:pagination).paginate(1, 5000).all

      page_templ = File.read('app_data/templ_page.html')
      thread_templ = File.read('app_data/templ_thread.html')

      all = ''
      index = 0
      posts.group_by{|h| h[:tid]}.each do |k,v|
          thread = @@DB[:threads].filter(:tid => k).first
          title = "no found title for #{k}"
          title = thread[:title] if !thread.nil?

          post_htm = thread_templ.gsub(/@posts/, gen_posts(v.sort_by{ |pp| pp[:addeddate] },title))
          .gsub(/@threadTitle/,"#{index} #{title}")
          index +=1
          all += "<br />" + post_htm
      end

      user = @@DB[:users].filter(:uid => uid).first
      page_htm = page_templ.gsub(/@@@posts/, all).gsub(/@@@PageTitle/, "posts_#{user[:username]}")

      File.open(path, 'w') do |file|
          file.puts page_htm
      end

      system "firefox '#{path}'"
    end


    def self.gen_all_pages_thread(tid, path)
      posts = @@DB[:posts].filter(:tid => tid).order(:addeddate).all
      thread = @@DB[:threads].filter(:tid => tid).first
      title = thread[:title]

      page_templ = File.read('app_data/templ_page.html')
      page_htm = page_templ.gsub(/@@@posts/, gen_posts(posts,title)).gsub(/@@@PageTitle/, "thread_#{title}")
      File.open(path, 'w') do |file|
          file.puts page_htm
      end

      system "firefox '#{path}'"
    end

    def self.show_recent_posts(path, minuts)
      from = Helper.get_moscow_datetime - (minuts/1440.0)
      posts = @@DB[:posts].filter('addeddate > ?',from).order(:addeddate).all #reverse_order
      p posts.size

      page_templ = File.read('app_data/templ_page.html')
      thread_templ = File.read('app_data/templ_thread.html')
      all = ''
      index = 0
      posts.group_by{|h| h[:tid]}.each do |k,v|
          thread = @@DB[:threads].filter(:tid => k).first
          title = "no found title for #{k}"
          title = thread[:title] if !thread.nil?

          post_templ = File.read('app_data/templ_post_hover.html')

          post_htm = thread_templ.gsub(/@posts/, gen_posts(v, title, post_templ))
          .gsub(/@threadTitle/,"#{index} #{title}")
          index +=1
          all += "<br /><br />" + post_htm
      end

      page_htm = page_templ.gsub(/@@@posts/, all).gsub(/@@@PageTitle/, "last 60 min posts")

      File.open(path, 'w') do |file|
          file.puts page_htm
      end

      system "firefox '#{path}'"
    end

    def self.show_recent_users(path, minuts)
      from = Helper.get_moscow_datetime - (minuts/1440.0)
      posts = @@DB[:posts].filter('addeddate > ?',from).reverse_order(:addeddate).all
      #posts = @@DB[:posts].reverse_order(:addeddate).limit(250).all

      page_templ = File.read('app_data/templ_page.html')

      html = '<table class="msgTable">'
      index = 0
      posts.each do |p|

          index +=1
          date = p[:addeddate].to_s

          html += "<tr><td>#{p[:addedby]}</td><td>#{date}</td></tr>"
      end
      html += '</table>'

      page_htm = page_templ.gsub(/@@@posts/, html).gsub(/@@@PageTitle/, "last #{minuts} users")

      File.open(path, 'w') do |file|
          file.puts page_htm
      end

      system "firefox '#{path}'"
    end


    def self.gen_posts(posts, title, post_templ = File.read('app_data/templ_post.html'))

      res =[]
      posts.each_with_index do |p, ind|

          post_text = p[:text].gsub('http://www.sql.ru/forum','').gsub('http://nosql.ru/album','')
          pp = post_templ
          .gsub(/@title/, "#{ind}: #{title} ")
          .gsub(/@text/, post_text)
          .gsub(/@date/, p[:addeddate].to_s)
          .gsub(/@orig_url/, "http://www.sql.ru/forum/actualutils.aspx?action=gotomsg&tid=#{p[:tid]}&msg=#{p[:mid]}")
          .gsub(/@addedby/, p[:addedby])
          .gsub(/@uid/, p[:addeduid].to_s)

          res<<pp
      end
      #res.join('<br />')
      res.join('')
    end

end

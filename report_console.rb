require 'sequel'
require 'nokogiri'
require_relative  'helper'
require_relative  'repo'

class ConReport

    @@DB = Repo.get_conn


    def self.show_users_after_downloading(last)
      user_posts =  @@DB[:posts].filter('addeddate > ? ', last)
      .select(:addeduid, :addedby, :quote_user).all

      user_posts.group_by{|h| h[:addedby]}.sort_by{ |k,v| -v.size }.map do |k,v|
          puts "#{v.first[:addeduid]}\t#{k.ljust(35, ' ')} #{v.size}"
      end
    end

    def self.show_user_posts_from(uid, hours=0)

      hours ==0 ? 8 : hours

      from = Helper.get_moscow_datetime - hours/24.0
      threads = @@DB[:threads].filter('updateddate > ?',from).to_hash(:tid, :title)

      posts = @@DB[:posts].filter('addeddate > ?',from)
      .filter(:addeduid => uid)
      .order(:addeddate)
      .all

      posts.each do |ps|
          p "----- #{threads[ps[:tid]].strip}  #{ps[:addeddate].strftime("%F %k:%M ")}"
          html = ps[:text]
          puts format_post_text(html)
          puts
      end
    end

    def self.show_recent_users(hours=0)
      hours ==0 ? 8 : hours

      db = Repo.get_conn

      from = Helper.get_moscow_datetime - hours/24.0
      today_posts = db[:posts].filter('addeddate > ?',from)
      .order(:addeddate)
      .select(:addeduid, :addedby, :addeddate, :text, :tid, :quote_user).all

      threads = db[:threads].filter('updateddate > ?',from).to_hash(:tid, :title)

      user_quotes =  Hash[ today_posts.group_by{ |p| p[:quote_user] }.map{|k,v| [k, v.size]}]

      dates = [from]
      quotes = [user_quotes]


      today_posts.group_by{|h| h[:addedby]}.sort_by{|k,v| -v.size}.take(80).each do |k,v|
          puts "#{k.ljust(35, '_')}#{v.size}\t#{v.first[:addeduid]}"

      end
    end

    def self.show_recent_threads_with_posts(hours_start, hours_end)

      hours_start = 2 if hours_start==0


      from = Helper.get_moscow_datetime - (hours_start/24.0)
      to = Helper.get_moscow_datetime - (hours_end/24.0)

      posts = @@DB[:posts].filter('addeddate > ? and addeddate < ?', from, to).reverse_order(:addeddate).all #reverse_order

      threads = @@DB[:threads].filter('updateddate > ?',from).to_hash(:tid, :title)

      puts "*****[stat-new threads and posts from #{hours_start} to #{hours_end} back] threads = #{threads.size} posts=#{posts.size}"

      posts.group_by{|h| h[:tid]}.each_with_index do |(k,posts),tind|
          p "*** thr:#{tind}---#{threads[k].strip}(#{k})"
          puts

          posts.each_with_index do |ps, pind|
            p "*** post:#{pind}---#{ps[:addedby]}  #{ps[:addeddate].strftime("%F %k:%M ")}"
            html = ps[:text]
            puts format_post_text(html)
            puts
          end
          puts "*"*60
      end
      puts "*****[stat-new threads and posts from #{hours_start} to #{hours_end} back] threads = #{threads.size} posts=#{posts.size}"

    end
    def self.show_today_weblogs
      date0 = Helper.dt_now.to_date
      logs = @@DB[:logs].filter('date > ? and date < ?', date0, date0+1).order(:date).all #reverse_order

      logs.each_with_index do |ll, ind|
          puts ":#{ind}   #{ll[:ip]}  #{ll[:date].strftime("%F %k:%M ")} #{ll[:path]}"

      end
    end
    def self.show_today_botlogs(dayback=0)
      date0 = Helper.dt_now.to_date - dayback
      logs = @@DB[:botlogs].filter('date > ? and date < ?', date0, date0+1).order(:date).all #reverse_order

      logs.each_with_index do |ll, ind|
          puts "#{ll[:date].strftime("%F %k:%M ")} #{ll[:action]}"

      end
    end
    def self.format_post_text(html)
      f = Nokogiri::HTML.fragment(html)
      f.search('.//table').remove
      #f.search('.//img').remove
      f.to_s.strip.gsub("<br>","\n")
    end
end

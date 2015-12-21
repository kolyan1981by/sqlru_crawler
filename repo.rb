require 'sequel'
require 'pg'

require_relative  'models'
require_relative  'helper'
require_relative  'forum_parser'


class Repo

    #@@db = Sequel.connect('sqlite://ptlogs.sqlite')

    @@db = Sequel.connect(YAML::load(File.open('database.yml')))

    def self.get_conn
      @@db
    end

    def self.get_thread(tid)
      @@db[:threads].where(:tid=> tid)
    end

    def self.get_username(uid)
      user = @@db[:users].filter(:uid => uid).first
      user[:username]
    end

    def self.del_thread(tid)
      p @@db[:posts].filter(:tid => tid).delete
      @@db[:tpages].filter(:tid => tid).delete
    end

    def self.update_or_save_threads(threads)

      exist = @@db[:threads].select(:tid).map(:tid)

      #exist.collect!{|e| e.strip}

      threads.each do |t|
          if exist.include? t.tid
            @@db[:threads].where(:tid => t.tid).update(:updateddate => t.updated,:viewers => t.viewers,
                                                       :responses => t.responses)
          else
            @@db[:threads].insert(:tid => t.tid, :type =>0 , :fid => t.fid,
                                 :title => t.title, :viewers => t.viewers ,
                                 :responses => t.responses , :forumname=> t.forumname, :updateddate => t.updated)
          end
      end

    end

    def self.test(tid)
      p mids = @@db[:posts].filter(:tid => tid).map(:mid)
    end

    def self.save_posts(posts, tid, pg)

      #del_thread(tid)

      mids = @@db[:posts].filter(:tid => tid).map(:mid)

      users = @@db[:users].to_hash(:username, :uid)
      tusers = users.keys

      added = 0
      update_users(posts)
      counter=0

      posts.each do |p|
          counter+=1

          #begin

          if !mids.include? p.mid
            added+=1

            text =p.text.encode("utf-8")

            quoted = Helper.detect_quote_to(text,tusers)
            quote_userid = users[quoted] if quoted != p.addedname

            page_num = pg =='a'? (counter-1)/25 +1 : pg.to_i

            @@db[:posts].insert(:tid => tid, :mid => p.mid,
                              :type => 0, :text => text,
                              :addeduid => p.addeduid, :addedby => p.addedname,
                              :addeddate => p.addeddate, :quote_user=> quote_userid,
                              :pg => page_num)

          end

          #

      end
      update_pages_table(posts.size,tid,pg)

      added
    end

    def self.update_users(posts)
      uids = @@db[:users].map(:uid)
      added=[]

      posts.each do |p|
          

            if !uids.include? p.addeduid and !added.include? p.addeduid
                @@db[:users].insert(:username => p.addedname, :uid => p.addeduid)

                added<< p.addeduid
            end
         
      end
      
    end


      def self.update_pages_table(count, tid, pg)

         last_count = count

         if pg == 'a'
            create_new_pages(count,tid)
            
            pg, last_count  = Helper.calc_pgnum_count(count)
         end

         exist = @@db[:tpages].where(:tid=>tid, :page=>pg)
         
         if 1 != exist.update(:postcount => last_count)
            @@db[:tpages].insert(:tid=>tid, :page=>pg, :postcount => last_count)
         end
         
          #p "page #{pg} #{count}"
      end

         def self.create_new_pages(added, tid)

          max =  @@db[:tpages].where(:tid=>tid).select{max(page)}.first[:max].to_i

          pages = (added-1) / 25 + 1

            for i in ( max-1 .. max-1)
                @@db[:tpages].where(:tid=>tid,:page=>i).update(:postcount => 25)
            end if max > 1


            for i in (max+1 .. pages)
                count = i == pages ? added % 25 : 25
                @@db[:tpages].insert(:tid=>tid, :page=>i, :postcount => count)
            end
          end

          def self.page_posts_count(tid, pg)
            found = @@db[:tpages].where('tid=? and page=?',tid, pg).first
            if found.nil? then 0 else found[:postcount] end
          end

          def self.get_thread_page_count(tid)
            @@db[:tpages].where(:tid=>tid).to_hash(:page, :postcount)
          end

          def self.find_last_25page(tid)
            found =  @@db[:tpages].where('tid=? and postCount = 25',tid).order(:page).last
            if found.nil? then 0 else found[:page] end
          end

          def self.find_user_posts(uid)
            @@db[:posts].where(:addeduid=>uid).order(:addeddate).all
          end

          def self.find_thread_user_posts(tid, uid)
            @@db[:posts].where(:tid=>tid,:addeduid=>uid).order(:addeddate).all
          end

          def self.log_running(text)
            @@db[:botlogs].insert(:action => text, :date => DateTime.now.new_offset(3/24.0))
          end


          def self.find_last_running_date
            last = @@db[:botlogs].order(:date).last
            last[:date] if not last.nil?
          end
      end

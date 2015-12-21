require_relative  'repo'

class ErbalT < OpenStruct
    def render(template)
      ERB.new(template).result(binding)
    end
end


class ErbHelper
    def recent_users(hours=8)
      db = Repo.get_conn

      from = DateTime.now - hours/24.0
      today_posts = db[:posts].filter('addeddate > ?',from)
      .order(:addeddate)
      .select(:addeduid, :addedby, :addeddate, :text, :tid, :quote_user).all

      threads = db[:threads].filter('updateddate > ?',from).to_hash(:tid, :title)

      user_quotes =  Hash[ today_posts.group_by{ |p| p[:quote_user] }.map{|k,v| [k, v.size]}]

      posts = [ today_posts ]
      dates = [from]
      quotes = [user_quotes]


      et = ErbalT.new({ :posts => posts, :dates => dates, :quotes => quotes})
      page_htm = et.render(File.read('erb/users_for_week.erb'))

      path = File.dirname(__FILE__) + "/generated/recent_users.html"

      page_templ = File.read('app_data/templ_page.html')

      page_htm = page_templ.gsub(/@@@posts/, page_htm).gsub(/@@@PageTitle/, "today users")

      File.open(path, 'w') do |file|
          file.puts page_htm
      end

      system "firefox '#{path}'"
    end
end

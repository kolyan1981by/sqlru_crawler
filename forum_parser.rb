require_relative  'models'
require_relative  'forum_loader'
require_relative  'thread_loader'
require_relative  'thread_parser'
require_relative  'repo'
require_relative  'helper'
require 'parallel'

module ForumParser

  EXCLUDE_THREADS = [
    320996,614262,730199,1008845,
    312718, #prikolnye-sochetaniya-tem
    921462, #dorozhnoe-bezumie
    874158, #nu-che-tankovye-zadroty
    941856, #pro-hokkey-i-prochiy-sportivnyy-sport-s
    97362,  #ahtung-kto-razdayot-priglasheniya-v-area-51-chitayte-tut
    1108498, #neoficialnyy-klient-sql-ru-marat saved
    503820, #u-kogo-cho-shhas-poyot-igraet
    863214, #topeg-neveroyatnyh-faktov
    481205, #emmm-pyatnica
    310067, #ahtung-kto-razdayot-priglasheniya-v-zpt
    793998, #spisok-replikantov
    1072878, #rubl-vse-dollar-vin
    1042422, #Навальный. Заповедник
    218218, # Наши детки!
  ]


  def self.parse_subforum_page(fp)
    puts "start load #{fp}"

    page_threads = ForumLoader.get_threads(fp)

    Repo.update_or_save_threads(page_threads)

    all_pages =0

    results = Parallel.map_with_index(page_threads,:in_threads=>7) do |thr, ind|

      #threads.each_with_index do |thr, ind|
      next if EXCLUDE_THREADS.include? thr.tid


      posts = load_thread_page(thr,ind)

    end




    p "finished #{fp}"
  end

  def self.load_thread_page(thr,ind)
    dl_thr_pages =0

    pages_count = thr.pages.size


    pages_map = Repo.get_thread_page_count(thr.tid)

    res_pages =[]

    thr.pages.each do |tpage|

      url = tpage.href
      tid, pg = Helper.get_tid_pg(url)

      next if pages_map[pg] == 25

      posts = ThreadParser.check_db_get_post(url, thr.responses)

      #already downloaded,  responses the same
      if posts.nil?
        res =  "exist #{tid}-#{pg}"
      else
        dl_thr_pages += 1
        res_pages << [pg,posts.size]
      end

      break if  (pages_count>100 and dl_thr_pages >=1)
      break if  (pages_count>=30 and dl_thr_pages >=2)
      break if  (pages_count.between?(12,30) and dl_thr_pages >=3)

    end
    pages_map = pages_map.select{|k,v| v!=25}

    updt= thr.updated.strftime("%F %k:%M")

    puts "#{ind}: #{thr.tid} #{res_pages} #{thr.title} #{updt} #{pages_map}" if not res_pages.empty?

  end

end

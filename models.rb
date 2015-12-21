
class FThread
  attr_accessor :fid, :forumname, :tid, :title, :createdby, :viewers, :responses , :pages, :updated
  
  def initialize
    @pages = []
  end
end

class Url
  attr_accessor :href, :text, :need_redirect
end

class Post
  attr_accessor :mid,:tid, :text, :addedname, :addeduid, :addeddate
end
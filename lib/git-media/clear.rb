require 'git-media/status'

module GitMedia
  module Clear

    def self.run!
      @push = GitMedia.get_transport
      self.clear_local_cache
    end

    def self.clear_local_cache
      # find files in cache and delete all pushed files
      locals = Helpers.list_objects(GitMedia.cache_path).to_set
      pushed_files = @push.list(locals,nil)
      unpushed_files = locals-pushed_files

      pushed_files.each do |name|
        next unless name.hash?
        puts "#{name}: removed from cache"
        File.unlink(File.join(GitMedia.cache_path, name))
      end
    end
    
  end
end
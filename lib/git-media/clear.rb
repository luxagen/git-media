require 'git-media/status'

module GitMedia
  module Clear

    def self.run!
      @push = GitMedia.get_push_transport
      self.clear_local_cache
    end
    
    def self.clear_local_cache
      # find files in media buffer and delete all pushed files
      all_cache = Dir.chdir(GitMedia.cache_path) { Dir.glob('*') }
      unpushed_files = @push.get_unpushed(all_cache)
      pushed_files = all_cache - unpushed_files
      pushed_files.each do |hash|
        hash.enforce_sha1
        puts "Removing " + hash[0, 8] + " from cache"
        File.unlink(File.join(GitMedia.cache_path, hash))
      end
    end
    
  end
end
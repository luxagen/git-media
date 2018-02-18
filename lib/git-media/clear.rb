require 'git-media/status'

module GitMedia
  module Clear

    def self.run!
      @push = GitMedia.get_transport
      self.clear_local_cache
    end
    
    def self.clear_local_cache
      # find files in cache and delete all pushed files
      all_cache = Dir.chdir(GitMedia.cache_path) { Dir.glob('*') }
      unpushed_files = @push.get_unpushed(all_cache)
      pushed_files = all_cache-unpushed_files
      pushed_files.each do |name|
        next unless name.hash?
        puts "#{name}: removed from cache"
        File.unlink(File.join(GitMedia.cache_path, name))
      end
    end
    
  end
end
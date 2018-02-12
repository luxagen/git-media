require 'git-media/helpers'

module GitMedia
  module FilterSmudge

    def self.ensure_exists(hash)
      sha.enforce_hash

      cache_obj_path = GitMedia.media_path(hash)

      return cache_obj_path if File.exist?(cache_obj_path) # Early exit if the object is already cached

      # Read key from config
      auto_download = `git config git-media.autodownload`.chomp.downcase == "true"

      unless auto_download
        STDERR.puts('Object missing, writing placeholder: ' + hash)
        return nil
      end

      STDERR.puts ("Downloading: " + hash[0,8])
      pull = GitMedia.get_pull_transport
      pull.pull(nil, hash) # nil because this filter has no clue what file stdout will be piped into

      unless File.exist?(cache_obj_path)
        STDERR.puts ("Could not get object, writing stub : " + hash)
        return nil
      end

      return cache_obj_path
    end

    def self.run!
      STDIN.binmode
      STDOUT.binmode

      prefix = STDIN.read(GM_BUFFER_BYTES)

      unless hash = prefix.stub2hash
        # If the file isn't a stub, just pass it through
        STDERR.puts('Unknown git-media stub format')
        GitMedia.Helpers.copy(STDOUT,STDIN,prefix)
        return 0
      end

      unless cache_obj_path = ensure_exists(hash)
        print prefix # Pass stub through
        STDERR.puts(hash+': cannot expand from cache')
        return 0
      end

      # Reaching here implies that cache_obj_path exists
      STDERR.puts ("Expanding : " + hash[0,8])
      File.open(cache_obj_path, 'rb') do |f|
        GitMedia::Helpers.copy(STDOUT,f)
      end

      return 0
    end

  end
end

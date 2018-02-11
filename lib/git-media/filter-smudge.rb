require 'git-media/helpers'

module GitMedia
  module FilterSmudge

    def self.ensure_exists(sha)
      sha.enforce_hash

      cache_file = GitMedia.media_path(sha)

      return cache_file if File.exist?(cache_file) # Early exit if the object is already cached

      # Read key from config
      auto_download = `git config git-media.autodownload`.chomp.downcase == "true"

      unless auto_download
        STDERR.puts('Object missing, writing placeholder: ' + sha)
        return nil
      end

      STDERR.puts ("Downloading: " + sha[0,8])
      pull = GitMedia.get_pull_transport
      pull.pull(nil, sha) # nil because this filter has no clue what file stdout will be piped into

      unless File.exist?(cache_file)
        STDERR.puts ("Could not get object, writing stub : " + sha)
        return nil
      end

      return cache_file
    end

    def self.run!
      STDIN.binmode
      STDOUT.binmode

      prefix = STDIN.read(GM_BUFFER_BYTES)

      unless sha = prefix.stub2hash
        # If the file isn't a stub, just pass it through
        STDERR.puts('Unknown git-media stub format')
        GitMedia.Helpers.copy(STDOUT,STDIN,prefix)
        return 0
      end

      unless cache_file = ensure_exists(sha)
        print prefix # Pass stub through
        return 0
      end

      # Reaching here implies that cache_file exists
      STDERR.puts ("Expanding : " + sha[0,8])
      File.open(cache_file, 'rb') do |f|
        GitMedia::Helpers.copy(STDOUT,f)
      end

      return 0
    end

  end
end

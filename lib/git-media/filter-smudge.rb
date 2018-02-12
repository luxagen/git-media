require 'git-media/helpers'

module GitMedia
  module FilterSmudge

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

      unless cache_obj_path = GitMedia::Helpers.ensure_cached(hash,"true" == `git config git-media.autodownload`.chomp.downcase)
        print prefix # Pass stub through
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

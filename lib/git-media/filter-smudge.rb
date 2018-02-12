require 'git-media/helpers'

module GitMedia
  module FilterSmudge

    def self.run!(info_output=true)
      STDIN.binmode
      STDOUT.binmode

      prefix = STDIN.read(GM_BUFFER_BYTES)

      unless hash = prefix.stub2hash
        # If the file isn't a stub, just pass it through
        STDERR.puts 'not a git-media stub' if info_output
        GitMedia.Helpers.copy(STDOUT,STDIN,prefix)
        return 0
      end

      unless cache_obj_path = GitMedia::Helpers.ensure_cached(hash,"true" == `git config git-media.autodownload`.chomp.downcase)
        print prefix # Pass stub through
        return 0
      end

      # Reaching here implies that cache_obj_path exists
      STDERR.puts "#{hash}: expanding" if info_output
      File.open(cache_obj_path, 'rb') do |f|
        if hash != GitMedia::Helpers.copy_hashed(STDOUT,f)
          STDERR.puts "#{hash}: cache object failed hash check"
          return 1
        end
      end

      return 0
    end

  end
end

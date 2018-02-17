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

      autoDownload  =  "true" == `git config git-media.autodownload`.chomp.downcase
      directDownload  =  'true' == `git config git-media.directdownload`.chomp.downcase

      if autoDownload && directDownload
        STDERR.puts "#{hash}: downloading" if info_output
        return 1 unless GitMedia::Helpers.pull(STDOUT,hash)
        return 0
      end

      unless cache_obj_path = GitMedia::Helpers.ensure_cached(hash,autoDownload) # TODO make ensure_cached always download and put autoDownload check here
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

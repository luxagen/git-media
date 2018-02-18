require 'git-media/helpers'

module GitMedia
  module FilterSmudge

    def self.expand(ostr,hash,prefix,autoDownload,directDownload,info_output)
      hash.enforce_hash

      if autoDownload&&directDownload
        STDERR.puts "#{hash}: downloading" if info_output
        return GitMedia::Helpers.pull(ostr,hash)
      end

      unless cache_obj_path = GitMedia::Helpers.ensure_cached(hash,autoDownload) # TODO make ensure_cached always download and put autoDownload check here
        STDERR.puts "#{hash}: missing, keeping stub"
        ostr.print prefix # Pass stub through
        return true
      end

      # Reaching here implies that cache_obj_path exists
      STDERR.puts "#{hash}: expanding" if info_output
      File.open(cache_obj_path, 'rb') do |ostr|
        if hash != GitMedia::Helpers.copy_hashed(STDOUT,ostr)
          STDERR.puts "#{hash}: cache object failed hash check"
          return false
        end
      end

      return true
    end

    def self.run!(info_output=true)
      STDIN.binmode
      STDOUT.binmode

      prefix = STDIN.read(GM_BUFFER_BYTES)

      unless hash = prefix.stub2hash
        # If the file isn't a stub, just pass it through
        STDERR.puts 'not a git-media stub' if info_output
        GitMedia::Helpers.copy(STDOUT,STDIN,prefix)
        return 0
      end

      autoDownload  =  "true" == `git config git-media.autodownload`.chomp.downcase
      directDownload  =  'true' == `git config git-media.directdownload`.chomp.downcase

      return 1 unless expand(STDOUT,hash,prefix,autoDownload,directDownload,info_output)
      return 0
    end

  end
end

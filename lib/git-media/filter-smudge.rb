require 'git-media/helpers'

module GitMedia
  module FilterSmudge

    def self.run!(info_output=true)
      STDIN.binmode
      STDOUT.binmode

      prefix = STDIN.read(GM_BUFFER_BYTES)

      unless hash = prefix.stub2hash
        # If the file isn't a stub, just pass it through
        STDERR.puts 'git-media: not a stub' if info_output
        GitMedia::Helpers.copy(STDOUT,STDIN,prefix)

        # If the pipe broke (rather than the input legitimately ending), the stream is truncated
        GitMedia::Helpers.check_abort

        return 0
      end

      autoDownload  =  "true" == `git config git-media.autodownload`.chomp.downcase

      begin
        return 0 if GitMedia.get_object(STDOUT,hash,autoDownload,info_output)
      rescue
        puts hash
        raise
      end

      return 1 # unreachable
    end

  end
end

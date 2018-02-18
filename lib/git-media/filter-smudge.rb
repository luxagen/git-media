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
        GitMedia::Helpers.copy(STDOUT,STDIN,prefix)
        return 0
      end

      autoDownload  =  "true" == `git config git-media.autodownload`.chomp.downcase

      # TODO ABORT CHECKING

      return 1 unless GitMedia.get_object(STDOUT,hash,autoDownload,info_output)
      return 0
    end

  end
end

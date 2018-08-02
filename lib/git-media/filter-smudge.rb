require 'git-media/helpers'

module GitMedia
  module FilterSmudge

    def self.run!(info_output=true)
      STDIN.binmode
      STDOUT.binmode

      prefix = STDIN.read(GM_BUFFER_BYTES)

      unless prefix
        STDERR.puts "git-media filter-smudge: skipping empty file" if info_output
        return 0
      end

      GitMedia::Helpers.copy(STDOUT,STDIN,prefix)

      # If the pipe broke (rather than the input legitimately ending), the stream is truncated
      GitMedia::Helpers.check_abort

      return 0
    end

  end
end

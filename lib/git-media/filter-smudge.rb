require 'git-media/helpers'

module GitMedia
  module FilterSmudge

    def self.run!(tree_path, info_output=true)
      STDIN.binmode
      STDOUT.binmode

      prefix = STDIN.read(GM_BUFFER_BYTES)

      unless prefix
#        STDERR.puts "git-media filter-smudge: skipping empty file" if info_output
        return 0
      end

      unless hash = prefix.stub2hash
        # If the file isn't a stub, just pass it through
        STDERR.puts "Warning: #{tree_path} is not a stub!" if info_output
        GitMedia::Helpers.copy(STDOUT,STDIN,prefix)

        # If the pipe broke (rather than the input legitimately ending), the stream is truncated
        GitMedia::Helpers.check_abort

        return 0
      end

      autoDownload  =  "true" == `git config git-media.autodownload`.chomp.downcase

      begin
        GitMedia.get_object(STDOUT,hash,autoDownload,info_output)
      rescue Exception => e
        puts hash
        STDERR.puts e
        return 1
      end
    end

  end
end

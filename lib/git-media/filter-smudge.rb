require 'git-media/helpers'

module GitMedia
  module FilterSmudge

    def self.run!
      media_buffer = GitMedia.get_media_buffer
      
      # read checksum size
      STDIN.binmode
      STDOUT.binmode
      orig = STDIN.readline(64)

      if sha = orig.stub2hash
        # this is a media file
        media_file = File.join(media_buffer, sha)
        if File.exists?(media_file)
          STDERR.puts('Recovering media : ' + sha)
          File.open(media_file, 'rb') do |f|
            unless GitMedia::Helpers.copy(STDOUT, f) return 1
          end
        else
          # Read key from config
          auto_download = `git config git-media.autodownload`.chomp.downcase == "true"

          if auto_download

            pull = GitMedia.get_pull_transport

            cache_file = GitMedia.media_path(sha)
            if !File.exist?(cache_file)
              STDERR.puts ("Downloading : " + sha[0,8])
              # Download the file from backend storage
              # We have no idea what the final file will be (therefore nil)
              pull.pull(nil, sha)
            end

            if File.exist?(cache_file)
              STDERR.puts ("Expanding : " + sha[0,8])
              File.open(media_file, 'rb') do |f|
                unless GitMedia::Helpers.copy(STDOUT, f) return 2
              end
            else
              STDERR.puts ("Could not get object, writing placeholder : " + sha)
              puts orig
            end

          else
            STDERR.puts('Object missing, writing placeholder : ' + sha)
            # Print orig and not sha to preserve eventual newlines at end of file
            # To avoid git thinking the file has changed
            puts orig
          end
        end
      else
        # if it is not a 40 character long hash, just output
        STDERR.puts('Unknown git-media stub format')
        unless GitMedia::Helpers::copy(STDOUT,STDIN,orig) return 3
      end

      return 0
    end

  end
end

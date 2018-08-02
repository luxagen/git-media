require 'tempfile'
require 'git-media/helpers'

module GitMedia
  module FilterClean

    def self.run!(input=STDIN, output=STDOUT, info_output=true)
      
      input.binmode
      output.binmode

      # Read the first data block
      prefix = input.read(GM_BUFFER_BYTES)

      unless prefix
        STDERR.puts "git-media filter-clean: skipping empty file" if info_output
        return 0
      end

      # Copy the data to a temporary filename within the local cache while hashing it
      hash = GitMedia::Helpers.copy_hashed(output,input,prefix)
      return 1 unless hash

      # If the pipe broke (rather than the input legitimately ending), the cached object is truncated and the hash is 
      # invalid; return nothing and allow the temp file to auto-delete
      GitMedia::Helpers.check_abort

      return 0
    end

  end
end

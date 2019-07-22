require 'tempfile'
require 'git-media/helpers'

module GitMedia
  module FilterClean

    def self.run!(tree_path, input=STDIN, output=STDOUT, info_output=true)
      
      input.binmode
      output.binmode

      # Read the first data block
      prefix = input.read(GM_BUFFER_BYTES)

      unless prefix
#        STDERR.puts "git-media filter-clean: skipping empty file" if info_output
        return 0
      end

      if hash = prefix.stub2hash
        # If the pipe broke (rather than the input legitimately ending), the cached object is truncated and the hash is 
        # invalid; return nothing and allow the temp file to auto-delete
        GitMedia::Helpers.check_abort

        output.write(prefix) # Pass the stub through
        STDERR.puts "Warning: #{tree_path} is a stub" if info_output
        return 0
      end

      start = Time.now

      # Copy the data to a temporary filename within the local cache while hashing it
      tempfile = Tempfile.new('media', GitMedia.cache_path, :binmode => true)
      hash = GitMedia::Helpers.copy_hashed(tempfile,input,prefix)
      return 1 unless hash

      # If the pipe broke (rather than the input legitimately ending), the cached object is truncated and the hash is 
      # invalid; return nothing and allow the temp file to auto-delete
      GitMedia::Helpers.check_abort

      # We got here, so we have a complete temp copy and a valid hash; explicitly close the tempfile to prevent 
      # autodeletion, then give it its final name (the hash)
      tempfile.close
      FileUtils.mv(tempfile.path, GitMedia.cache_obj_path(hash))

#      strElapsed = (Time.now - start).to_s

      output.puts hash # Substitute stub for data
      GitMedia::Helpers.print_clean(STDERR, tree_path, hash) if info_output

      return 0
    end

  end
end

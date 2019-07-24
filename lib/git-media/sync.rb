# Find 41-byte stub files and expand them from local cache (or remote store if not cached)
# Upload cached objects that are not in the remote store
require 'git-media/status'
require 'shellwords'

module GitMedia
  module Sync

    def self.run!
      @push = @pull = GitMedia.get_transport

      self.expand_references
      self.update_index
      self.upload_local_cache
    end

    def self.expand_references
      status = GitMedia::Status.find_references
      strCount = status[:to_expand].length.to_s

      info_output=true

      status[:to_expand].each_with_index do |tuple, index|
        tree_file = tuple[0]
        hash = tuple[1].enforce_hash

        GitMedia::Helpers.print_smudge(STDOUT, tree_file, hash, " [#{(index+1).to_s}/#{strCount}]") if info_output

        # Copy the data to a temporary filename within the working tree while hashing it
        tempfile = Tempfile.new('media','.',:binmode => true)

        begin
          GitMedia.get_object(tempfile,tree_file,hash,true,info_output)
        rescue
          # It's apparently good practice to do this explicitly rather than relying on the GC
          tempfile.close
          tempfile.unlink
          raise
        end

        # We got here, so we have a complete temp copy and a valid hash; explicitly close the tempfile to prevent 
        # autodeletion, then give it its final name (the hash)
        tempfile.close
        FileUtils.mv(tempfile.path,tree_file)

      end
    end

    def self.update_index
      refs = GitMedia::Status.find_references

      # Split references up into lists of at most 500
      # because most OSs have limits on the size of the argument list
      # TODO: Could probably use the --stdin flag on git update-index to be
      # able to update it in a single call
      refLists = refs[:expanded].each_slice(500).to_a

      refLists.each {
        |refList|

        `git update-index --assume-unchanged -- #{Shellwords.shelljoin(refList)}`
      }

      puts 'updated git index'
    end

    def self.upload_local_cache
      # find files in media buffer and upload them
      all_cache = Dir.chdir(GitMedia.cache_path) { Dir.glob('*') }
      all_cache_set = all_cache.to_set
      unpushed_files = @push.list(all_cache_set,all_cache_set)

      strCount = unpushed_files.length.to_s

      unpushed_files.each_with_index do |hash, index|
        strIdx = (index+1).to_s
        puts "#{hash}: uploading [#{strIdx}/#{strCount}]"
        GitMedia.push(
          hash,
          File.open(
            File.join(GitMedia.cache_path, hash),
            'rb'))
      end
      # TODO: if --clean, remove them
    end

  end
end

require 'digest/sha1'

GM_HASH_REGEX=/^[0-9a-f]{40}\z/

class String

  def hash?
    return self if self && self.match(GM_HASH_REGEX) # Must be truthy, exactly 40 caracters long, and contain only lowercase hex
  end

  def enforce_hash
    raise "'" + self + "' is not a valid SHA1 hash!" unless self.hash?
    return self
  end

  # If data is truthy, has the right length for a stub, and is a newline-terminated hex hash, return the hash; otherwise return nil
  def stub2hash
    # TODO: Maybe add some additional marker in the files like
    # "[hex string]:git-media"
    # to really be able to say that a file is a stub
    return self[0..-2] if self && self[-1]=="\n" && self[0..-2].match(GM_HASH_REGEX)
  end

end

GM_BUFFER_BYTES=1048576

module GitMedia
  module Helpers

    def self.copy(ostr,istr,prefix = istr.read(GM_BUFFER_BYTES))
      return nil if !prefix

      begin
        ostr.write prefix

        while data = istr.read(GM_BUFFER_BYTES) do
          ostr.write data
        end
      rescue
        return nil
      end

      return true
    end

    def self.copy_hashed(ostr,istr,prefix = istr.read(GM_BUFFER_BYTES))
      return nil if !prefix

      hashfunc = Digest::SHA1.new
      hashfunc.update(prefix)

      begin
        ostr.write(prefix)

        while data = istr.read(GM_BUFFER_BYTES)
          hashfunc.update(data)
          ostr.write(data)
        end
      rescue
        return nil
      end

      return hashfunc.hexdigest.enforce_hash
    end

    def self.expand(ostr,hash,download,info_output)
      hash.enforce_hash

      download ||== `git config git-media.autodownload`.chomp.downcase
      directDownload  =  'true' == `git config git-media.directdownload`.chomp.downcase

      cache_obj_path = GitMedia.cache_obj_path(hash)

      unless File.exist?(cache_obj_path)
        unless download
          # Fail and preserve stub
          STDERR.puts "#{hash}: missing, keeping stub"
          ostr.puts hash
          return true # Success (of a sort)
        end

        STDERR.puts "#{hash}: downloading" if info_output

        if directDownload
          # Download straight to ostr
          return GitMedia.get_transport.read(hash) do |istr|
            if hash != copy_hashed(ostr,istr)
              STDERR.puts "#{hash}: rehash failed during download"
              next false
            end
            next true
          end
        end

        # We want to dowload but direct downloads are disabled, so just download to cache
        unless download_to_cache(cache_obj_path,hash)
          STDERR.puts "#{hash}: download failed"
          return false
        end

        STDERR.puts "#{hash}: downloaded"
      end

      # Getting here implies that the matching object is in the cache, so expand it
      STDERR.puts "#{hash}: expanding" if info_output
      return File.open(cache_obj_path, 'rb') do |ostr|
        if hash != copy_hashed(STDOUT,ostr)
          STDERR.puts "#{hash}: cache object failed hash check"
          next false
        end

        next true
      end
    end

    def self.download_to_cache(cache_obj_path,hash)
      hash.enforce_hash

      GitMedia.get_transport.read(hash) do |istr|
        File.open(cache_obj_path, 'wb') do |ostr|
          if hash != GitMedia::Helpers.copy_hashed(ostr,istr)
            STDERR.puts "#{hash}: rehash failed during download"
            exit 1
          end
        end
      end

      return File.exist?(cache_obj_path)
    end

    def self.aborted?
      # I really really hate having to do this, but it's a reasonably reliable kludge to give a dying git parent process time to 
      sleep 0.1
      return 1 == Process.ppid # TODO make this look for any reparenting rather than PPID 1
    end

    def self.check_abort
      exit 1 if aborted?
    end

    def self.push(hash,istr)
      return GitMedia.get_transport.write(hash) do |ostr|
        if hash != copy_hashed(ostr,istr)
          STDERR.puts "#{hash}: rehash failed during upload"
          next false
        end

        next true
      end
    end

  end
end
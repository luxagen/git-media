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
    def self.list_objects(path)
      return Dir.chdir(path) { Dir.entries('.').select { |f| File.file?(f) && f.hash? }}
    end

    def self.shorten(hash)
      return hash[0, 12]
    end

    def self.print_mapping(ostr, file, hash, suffix='')
      ostr.puts "  #{shorten(hash)}: #{file}#{suffix}"
    end

    def self.print_clean(ostr, file, hash, suffix='')
      ostr.puts "  #{shorten(hash)} <- #{file}#{suffix}"
    end

    def self.print_smudge(ostr, file, hash, suffix='')
      ostr.puts "  #{shorten(hash)} -> #{file}#{suffix}"
    end

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

    def self.aborted?
      # I really really hate having to do this, but it's a reasonably reliable kludge to give a dying git parent process time to exit completely
      sleep 0.1
      return 1 == Process.ppid # TODO make this look for any reparenting rather than PPID 1
    end

    def self.check_abort
      exit 1 if aborted?
    end

  end
end

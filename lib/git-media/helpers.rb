require 'digest/sha1'

class String

  def hash?
    return self if self && self.match(/^[0-9a-f]{40}\z/) # Must be truthy, exactly 40 caracters long, and contain only lowercase hex
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
    return self[0..-2] if self && self.match(/^[0-9a-f]{40}\n\z/)
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

  end
end
require 'git-media/transport'

require 'set'

# Implements local (accessible via a filesystem path) object store

# git-media.transport local
# git-media.path /opt/media

module GitMedia
  module Transport
    class Local < Base

      def error_inaccessible
        raise "local store '#{@path}' is inaccessible"
      end

      def initialize
        @path = `git config git-media.path`.chomp
        if @path === ""
          raise "git-media.path not set for local transport"
        end
      end

      def read(hash)
        error_inaccessible unless Dir.exist?(@path)

        begin
          return File.open(File.join(@path, hash), 'rb') do |istr|
            value = yield istr
            next value
          end
        rescue
        end

        raise "#{hash}: remote object inaccessible"
      end

      def write(hash)
        error_inaccessible unless Dir.exist?(@path)

        temp = File.join(@path,'obj.temp')

        result=false

        begin
          result = File.open(temp,'wb') do |ostr|
            value = yield ostr
            next value
          end
        rescue
          raise "#{hash}: unable to create remote object"
        end

        FileUtils.mv(temp,File.join(@path, hash),:force => true) if result
        return result
      end

      def list(intersect,excludeFrom)
        upstream = `ls '#{@path}/' -1ap 2>/dev/null`.split("\n").select { |f| f.match(GM_HASH_REGEX) }.to_set

        error_inaccessible if 0 != $?.exitstatus

        intersected  =  intersect ? upstream&intersect : upstream

        return excludeFrom ? excludeFrom-intersected : intersected
      end

    end
  end
end

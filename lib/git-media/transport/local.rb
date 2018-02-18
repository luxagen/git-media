require 'git-media/transport'

require 'set'

# Implements local (accessible via a filesystem path) object store

# git-media.transport local
# git-media.localpath /opt/media

module GitMedia
  module Transport
    class Local < Base

      def initialize
        @path = `git config git-media.localpath`.chomp
        if @path === ""
          raise "git-media.localpath not set for local transport"
        end
      end

      def read(hash)
        return File.open(File.join(@path, hash), 'rb') do |istr|
          STDERR.puts "before yield"
          value = yield istr
          STDERR.puts "after yield"
          next value
        end

        return false
      end

      def write(hash)
        temp = File.join(@path,'obj.temp')

        result=false

        result = File.open(temp,'wb') do |ostr|
          STDERR.puts 'before yield'
          value = yield ostr
          STDERR.puts 'after yield'
          next value
        end

        FileUtils.mv(temp,File.join(@path, hash),:force => true) if result
        return result
      end

      def list(intersect,excludeFrom)
        results =  `ls #{@path} -p 2>/dev/null | grep -v /$`

        STDERR.puts "local store '#{@path}' is inaccessible" if $?.exitstatus > 0

        upstream = results.split("\n").to_set;

        intersected  =  intersect ? upstream&intersect : upstream

        return excludeFrom ? excludeFrom-intersected : intersected
      end

    end
  end
end

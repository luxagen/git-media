require 'git-media/transport'

require 'set'

# move large media to local bin

# git-media.transport local
# git-media.localpath /opt/media

module GitMedia
  module Transport
    class Local < Base

      def initialize(path)
        @path = path
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

      ###################################

      def write?
        File.exist?(@path)
      end

      def get_unpushed(files)
        results =  `ls #{@path} -p 2>/dev/null | grep -v /`

        STDERR.puts "local store '#{@path}' is inaccessible" if $?.exitstatus

        keys  = results.split("\n").to_set;

        files.select do |f|
          !keys.include?(f)
        end
      end
      
    end
  end
end

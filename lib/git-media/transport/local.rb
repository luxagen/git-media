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

      def read?
        File.exist?(@path)
      end

      def get_file(sha, to_file)
        from_file = File.join(@path, sha)
        if File.exists?(from_file)
          FileUtils.cp(from_file, to_file)
          return true
        end
        return false
      end

      def write?
        File.exist?(@path)
      end

      def put_file(sha, from_file)
        to_file = File.join(@path, sha)
        if File.exists?(from_file)
          FileUtils.cp(from_file, to_file)
          return true
        end
        return false
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

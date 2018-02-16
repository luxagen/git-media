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

      def read_store_obj(hash)
          store_obj_path = File.join(@path, hash)
          return File.open(store_obj_path, 'rb')
      end

      def get_file(hash, to_file)
        istr=read_store_obj(hash)
        from_file = File.join(@path, hash)

        begin
          File.open(to_file, 'wb') do |ostr|
            if hash != GitMedia::Helpers.copy_hashed(ostr,istr)
              STDERR.puts "#{hash}: remote object failed hash check"
              istr.close
              FileUtils.rm to_file
              return false
            end
          end
        rescue
          istr.close
          raise
        end

        return true
      end

      def write?
        File.exist?(@path)
      end

      def put_file(hash, from_file)
        to_file = File.join(@path, hash)
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

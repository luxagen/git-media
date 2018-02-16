module GitMedia
  module Transport
    class Base

      def pull(tree_file, hash)
        get_file(hash, GitMedia.cache_obj_path(hash))
      end

      def push(hash)
        put_file(hash, GitMedia.cache_obj_path(hash))
      end

      def get_file(hash, to_file)
        istr=read_store_obj(hash)

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

      ## OVERWRITE ##
      
      def read?
        false
      end

      def write?
        false
      end

      def put_file(hash, to_file)
        false
      end
      
      def get_unpushed(files)
        files
      end
      
      def read_store_obj(hash)
          false
      end

    end
  end
end
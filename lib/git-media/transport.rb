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
              STDERR.puts "#{hash}: rehash failed during download"
              istr.close
              FileUtils.rm to_file # Kill bad copy
              return false
            end
          end
        rescue
          istr.close
          raise
        end

        return true
      end

      def get_file2(hash, ostr)
        istr=read_store_obj(hash)

        begin
          if hash != GitMedia::Helpers.copy_hashed(ostr,istr)
            STDERR.puts "#{hash}: rehash failed during download"
            istr.close
            FileUtils.rm to_file # Kill bad copy
            return false
          end
        rescue
          istr.close
          raise
        end

        return true
      end

      def put_file(hash, from_file)
        ostr=write_store_obj(hash)

        begin
          File.open(from_file, 'rb') do |istr|
            if hash != GitMedia::Helpers.copy_hashed(ostr,istr)
              STDERR.puts "#{hash}: rehash failed during upload"
              ostr.close
              kill_store_obj(hash) # Kill bad copy
              return false
            end
          end
        rescue
          ostr.close
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

      def get_unpushed(files)
        files
      end
      
      def read_store_obj(hash)
          false
      end

      def kill_store_obj(hash)
        false
      end
    end
  end
end
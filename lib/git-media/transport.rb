module GitMedia
  module Transport
    class Base

      def pull(final_file, hash)
        to_file = GitMedia.cache_obj_path(hash)
        get_file(hash, to_file)
      end

      def push(hash)
        from_file = GitMedia.cache_obj_path(hash)
        put_file(hash, from_file)
      end

      ## OVERWRITE ##
      
      def read?
        false
      end

      def write?
        false
      end

      def get_file(hash, to_file)
        false
      end

      def put_file(hash, to_file)
        false
      end
      
      def get_unpushed(files)
        files
      end
      
    end
  end
end
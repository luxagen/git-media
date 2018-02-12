module GitMedia
  module Transport
    class Base

      def pull(tree_file, hash)
        get_file(hash, GitMedia.cache_obj_path(hash))
      end

      def push(hash)
        put_file(hash, GitMedia.cache_obj_path(hash))
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
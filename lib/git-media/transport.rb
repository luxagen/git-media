module GitMedia
  module Transport
    class Base

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
      
      def read(hash)
        false
      end

      def write(hash)
        false
      end

      def list(set)
        false
      end
    end
  end
end
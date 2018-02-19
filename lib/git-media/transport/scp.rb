require 'git-media/transport'

require 'set'

# Implements object store at an SCP path

# git-media.transport scp
# git-media.scpuser someuser
# git-media.scphost remoteserver.com
# git-media.scppath /opt/media

module GitMedia
  module Transport
    class Scp < Base

      def initialize
        @user = `git config git-media.scpuser`.chomp
        @host = `git config git-media.scphost`.chomp
        @path = `git config git-media.scppath`.chomp
        port = `git config git-media.scpport`.chomp
        if @user === ""
          raise "git-media.scpuser not set for scp transport"
        end
        if @host === ""
          raise "git-media.scphost not set for scp transport"
        end
        if @path === ""
          raise "git-media.scppath not set for scp transport"
        end

        if port
          @sshport = "-p#{port}"
          @scpport = "-P#{port}"
        end
      end

      def read(hash)
#        error_inaccessible unless Dir.exist?(@path)

        begin
#          command = "scp -q #{@scpport} \"#{@user}@#{@host}:#{File.join(@path, hash)}\" /dev/stdout 2>/dev/null"
          return IO.popen("scp -q #{@scpport} \"#{@user}@#{@host}:#{File.join(@path, hash)}\" /dev/stdout 2>/dev/null", 'rb') do |istr|
            value = yield istr
            next value
          end
        rescue
          STDERR.puts "#{hash}: remote object inaccessible"
        end

        return false
      end

      def write(hash)
#        error_inaccessible unless Dir.exist?(@path)

#        temp = File.join(@path,'obj.temp')

#        result=false

#        begin
#          result = File.open(temp,'wb') do |ostr|
#            value = yield ostr
#            next value
#          end
#        rescue
#          STDERR.puts "#{hash}: unable to create remote object"
#        end

#        FileUtils.mv(temp,File.join(@path, hash),:force => true) if result
#        return result
      end

      def list(intersect,excludeFrom)
        upstream = `ssh #{@user}@#{@host} #{@sshport} ls #{@path}/ -1ap 2>/dev/null`.split("\n").select { |f| f.match(GM_HASH_REGEX) }.to_set

        error_inaccessible if 0 != $?.exitstatus

        intersected  =  intersect ? upstream&intersect : upstream

        return excludeFrom ? excludeFrom-intersected : intersected
      end

      #################################################################

      def is_in_store?(obj)
        if `ssh #{@user}@#{@host} #{@sshport} [ -f "#{obj}" ] && echo 1 || echo 0`.chomp == "1"
          STDERR.puts(obj + " exists")
          return true
        else
          STDERR.puts(obj + " doesn't exist")
          return false
        end
      end

      def read?
        return true
      end

      def get_file(hash, to_file)
        from_file = @user+"@"+@host+":"+File.join(@path, hash)
        `scp #{@scpport} "#{from_file}" "#{to_file}"`
        if $? == 0
          STDERR.puts(hash + " downloaded")
          return true
        end
        STDERR.puts("#{hash}: download failed")
        return false
      end

      def write?
        return true
      end

      def put_file(hash, from_file)
        to_file = @user+"@"+@host+":"+File.join(@path, hash)
        `scp #{@scpport} "#{from_file}" "#{to_file}"`
        if $? == 0
          STDERR.puts(hash + " uploaded")
          return true
        end
        STDERR.puts(hash + " upload failed")
        return false
      end
      
      def get_unpushed(files)
        results =  `ssh #{@user}@#{@host} #{@sshport} ls #{@path} -p | grep -v /`

        keys  = results.split("\n").to_set;

        files.select do |f|
          !keys.include?(f)
        end
      end
      
    end
  end
end

require 'git-media/transport'

require 'set'

# Implements object store at an SSH path

# git-media.transport ssh
# git-media.user someuser
# git-media.host remoteserver.com
# git-media.path /opt/media

module GitMedia
  module Transport
    class SSH < Base

      def initialize
        @path = `git config git-media.path`.chomp
        if ''===@path
          raise "git-media.path not set for SSH transport"
        end

        user = `git config git-media.user`.chomp
        host = `git config git-media.host`.chomp
        if ''===user
          raise "git-media.user not set for SSH transport"
        end
        if ''===host
          raise "git-media.host not set for SSH transport"
        end

        port = `git config git-media.port`.chomp
        portsw  =  ''==port ? '' : " -p#{port}"

        @sshcmd = "ssh#{portsw} #{user}@#{host}"
      end

      def read(hash)
        begin
          cmd="#{@sshcmd} 'cat <\"#{File.join(@path,hash)}\" 2>/dev/null'"
          return IO.popen(cmd,'rb') do |istr|
            value = yield istr
            next value
          end
        rescue
        end

        raise "#{hash}: remote object inaccessible"
      end

      def write(hash)
#        error_inaccessible unless Dir.exist?(@path)
        # TODO RETURN CODES

        begin
          cmd="#{@sshcmd} 'cat >\"#{File.join(@path,hash)}\" 2>/dev/null'"
          return IO.popen(cmd,'wb') do |ostr|
            value = yield ostr
            next value
          end
        rescue
        end

        raise "#{hash}: cannot create remote object"
      end

      def list(intersect,excludeFrom)
        cmd = "#{@sshcmd} ls '#{@path}/' -1ap 2>/dev/null"
        upstream = `#{cmd}`.split("\n").select { |f| f.match(GM_HASH_REGEX) }.to_set

        error_inaccessible if 0 != $?.exitstatus

        intersected  =  intersect ? upstream&intersect : upstream

        return excludeFrom ? excludeFrom-intersected : intersected
      end
      
    end
  end
end

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
        @path = `git config git-media.scppath`.chomp
        if ''===@path
          raise "git-media.scppath not set for scp transport"
        end

        user = `git config git-media.scpuser`.chomp
        host = `git config git-media.scphost`.chomp
        port = `git config git-media.scpport`.chomp
        if ''===user
          raise "git-media.scpuser not set for scp transport"
        end
        if ''===host
          raise "git-media.scphost not set for scp transport"
        end
        portsw  =  ''==port ? '' : " -p#{port}"
        @sshcmd = "ssh#{portsw} #{user}@#{host}"
      end

      def read(hash)
#        error_inaccessible unless Dir.exist?(@path)
        # TODO RETURN CODES

        begin
          cmd="#{@sshcmd} 'cat <\"#{File.join(@path,hash)}\" 2>/dev/null'"
          return IO.popen(cmd,'rb') do |istr|
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
        # TODO RETURN CODES

        begin
          cmd="#{@sshcmd} 'cat >\"#{File.join(@path,hash)}\" 2>/dev/null'"
          return IO.popen(cmd,'wb') do |ostr|
            value = yield ostr
            next value
          end
        rescue
          STDERR.puts "#{hash}: cannot create remote object"
        end

        return false
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

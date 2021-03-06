require 'rubygems'
require 'bundler/setup'

require 'trollop'
require 'fileutils'
require 'tempfile'

require 'git-media/helpers'

module GitMedia

  def self.cache_path
    @@git_dir ||= `git rev-parse --git-dir`.chomp
    media_buffer = File.join(@@git_dir, 'media/objects')
    FileUtils.mkdir_p(media_buffer) if !File.exist?(media_buffer)
    return media_buffer
  end

  def self.cache_obj_path(hash)
    hash.enforce_hash
    buf = self.cache_path
    File.join(buf, hash)
  end

  def self.get_credentials_from_netrc(url)
    require 'uri'
    require 'netrc'

    uri = URI(url)
    hostname = uri.host
    unless hostname
      raise "Cannot identify hostname within git-media.webdavurl value"
    end
    netrc = Netrc.read
    netrc[hostname]
  end

  def self.get_transport
    transport = `git config git-media.transport`.chomp
    case transport
    when ""
      raise "git-media.transport not set"

    when "ssh"
      require 'git-media/transport/ssh'
      return GitMedia::Transport::SSH.new
    when "local"
      require 'git-media/transport/local'
      return GitMedia::Transport::Local.new
    when "s3"
      require 'git-media/transport/s3'

      bucket = `git config git-media.s3bucket`.chomp
      key = `git config git-media.s3key`.chomp
      secret = `git config git-media.s3secret`.chomp
      if bucket === ""
        raise "git-media.s3bucket not set for s3 transport"
      end
      if key === ""
        raise "git-media.s3key not set for s3 transport"
      end
      if secret === ""
        raise "git-media.s3secret not set for s3 transport"
      end
      GitMedia::Transport::S3.new(bucket, key, secret)

    when "atmos"
      require 'git-media/transport/atmos_client'

      endpoint = `git config git-media.endpoint`.chomp
      uid = `git config git-media.uid`.chomp
      secret = `git config git-media.secret`.chomp
      tag = `git config git-media.tag`.chomp

      if endpoint == ""
        raise "git-media.endpoint not set for atmos transport"
      end

      if uid == ""
        raise "git-media.uid not set for atmos transport"
      end

      if secret == ""
        raise "git-media.secret not set for atmos transport"
      end
      GitMedia::Transport::AtmosClient.new(endpoint, uid, secret, tag)
    when "webdav"
      require 'git-media/transport/webdav'

      url = `git config git-media.webdavurl`.chomp
      user = `git config git-media.webdavuser`.chomp
      password = `git config git-media.webdavpassword`.chomp
      verify_server = `git config git-media.webdavverifyserver`.chomp == 'true'
      binary_transfer = `git config git-media.webdavbinarytransfer`.chomp == 'true'
      if url == ""
        raise "git-media.webdavurl not set for webdav transport"
      end
      if user == ""
        user, password = self.get_credentials_from_netrc(url)
      end
      if !user
        raise "git-media.webdavuser not set for webdav transport"
      end
      if !password
        raise "git-media.webdavpassword not set for webdav transport"
      end
      GitMedia::Transport::WebDav.new(url, user, password, verify_server, binary_transfer)
    when "box"
      require 'git-media/transport/box'

      client_id = `git config git-media.boxclientid`.chomp
      client_secret = `git config git-media.boxclientsecret`.chomp
      redirect_uri = `git config git-media.boxredirecturi`.chomp
      folder_id = `git config git-media.boxfolderid`.chomp

      access_token = `git config git-media.boxaccesstoken`.chomp
      refresh_token = `git config git-media.boxrefreshtoken`.chomp
      if client_id == ""
        raise "git-media.boxclientid not set for box transport"
      end
      if client_secret == ""
        raise "git-media.boxclientsecret not set for box transport"
      end
      if redirect_uri == ""
        raise "git-media.boxredirecturi not set for box transport"
      end
      if folder_id == ""
        raise "git-media.boxfolderid not set for box transport"
      end
      GitMedia::Transport::Box.new(client_id, client_secret, redirect_uri, folder_id, access_token, refresh_token)
    else
      raise "Invalid transport #{transport}"
    end
  end

  module Application
    def self.run!

      if !system('git rev-parse')
        return
      end

      cmd = ARGV.shift # get the subcommand
      cmd_opts = case cmd
        when "filter-clean" # parse delete options
          require 'git-media/filter-clean'
          return GitMedia::FilterClean.run!(ARGV.shift)
        when "filter-smudge"
          require 'git-media/filter-smudge'
          return GitMedia::FilterSmudge.run!(ARGV.shift)
        when "clear" # parse delete options
          require 'git-media/clear'
          return GitMedia::Clear.run!
        when "sync"
          require 'git-media/sync'
          return GitMedia::Sync.run!
        when 'status'
          require 'git-media/status'
          opts = Trollop::options do
            opt :force, "Force status"
            opt :short, "Short status"
          end
          return GitMedia::Status.run!(opts)
        when 'retroactively-apply'
          require 'git-media/filter-branch'
          GitMedia::FilterBranch.clean!
          arg2 = "--index-filter 'git media index-filter #{ARGV.shift}'"
          system("git filter-branch #{arg2} --tag-name-filter cat -- --all")
          return GitMedia::FilterBranch.clean!
        when 'index-filter'
          require 'git-media/filter-branch'
          return GitMedia::FilterBranch.run!
        else
    print <<EOF
usage: git media sync|status|clear

  sync                 Sync files with remote server

  status               Show files that are waiting to be uploaded and file size
                       --short:  Displays a shorter status message

  clear                Upload and delete the local cache of media files

  retroactively-apply  [Experimental] Rewrite history to add files from previous commits to git-media
                       Takes a single argument which is an absolute path to a file which should contain all file paths to rewrite
                       This file could for example be generated using
                       'git log --pretty=format: --name-only --diff-filter=A | sort -u | egrep ".*\.(jpg|png)" > to_rewrite'

EOF
        end

    end
  end

    def self.get_object(ostr, opath, hash, download, info_output)
      hash.enforce_hash

      if ('da39a3ee5e6b4b0d3255bfef95601890afd80709'==hash)
        # This is the null hash - generate an empty stream by exiting immediately with a warning
        STDERR.puts 'Warning: empty-object reference found!'
        return
      end

      download  ||=  'true' == `git config git-media.autodownload`.chomp.downcase
      directDownload  =  'true' == `git config git-media.directdownload`.chomp.downcase

      cache_obj_path = cache_obj_path(hash)

      shorthash = GitMedia::Helpers.shorten(hash)

      unless File.exist?(cache_obj_path)
        raise "Warning: #{shorthash} missing from cache!" unless download

        STDERR.puts "  #{shorthash}: downloading" if info_output

        # We want to download and direct downloads are enabled, so download straight to ostr
        return download_from_store(ostr,hash) if directDownload

        # We want to dowload but direct downloads are disabled, so just download to cache
        raise "  #{shorthash}: download failed" unless download_to_cache(cache_obj_path,hash)

        STDERR.puts "  #{shorthash}: downloaded"
      end

      # Getting here implies that the matching object is in the cache, so expand it
      GitMedia::Helpers.print_smudge(STDERR, opath, hash)

      return File.open(cache_obj_path, 'rb') do |istr|
        raise "  #{shorthash}: cache object failed hash check" if hash != GitMedia::Helpers.copy_hashed(ostr,istr)
      end
    end

    def self.download_from_store(ostr,hash)
      hash.enforce_hash

      shorthash = GitMedia::Helpers.shorten(hash)

      return get_transport.read(hash) do |istr|
        raise "  #{shorthash}: rehash failed during download" if hash != GitMedia::Helpers.copy_hashed(ostr,istr)
        next true
      end
    end

    def self.download_to_cache(cache_obj_path,hash)
      hash.enforce_hash

      # Copy the data to a temporary filename within the local cache while hashing it
      tempfile = Tempfile.new('media',cache_path,:binmode => true)

      begin
        download_from_store(tempfile,hash)
      rescue
        # It's apparently good practice to do this explicitly rather than relying on the GC
        tempfile.close
        tempfile.unlink
        raise
      end

      # We got here, so we have a complete temp copy and a valid hash; explicitly close the tempfile to prevent 
      # autodeletion, then give it its final name (the hash)
      tempfile.close
      FileUtils.mv(tempfile.path,cache_obj_path)
    end

    def self.push(hash,istr)
      shorthash = GitMedia::Helpers.shorten(hash)

      return get_transport.write(hash) do |ostr|
        raise "#{shorthash}: rehash failed during upload" if hash != GitMedia::Helpers.copy_hashed(ostr,istr)
        next true
      end
    end

end

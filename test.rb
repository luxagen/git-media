require 'rubygems'

require 'fileutils'

IO.popen("scp -q \"luxagen@luxagen.net:/git-media/images2/ae3ee9c11fb316633499bb7f6445c20b0d941df1\" /dev/stdout 2>/dev/null", 'rb') do |istr|
  File.open('test.jpg','wb') do |ostr|
    while data = istr.read(1048576) do
      ostr.write data
    end
  end
end


require File.join(File.dirname(__FILE__), %w[.. setup])

module TestLogging
module TestAppenders

  class TestRollingFile < Test::Unit::TestCase
    include LoggingTestCase

    NAME = 'roller'

    def setup
      super
      Logging.init

      @fn = File.join(TMP, 'test.log')
      @fn_fmt = File.join(TMP, 'test.%d.log')
      @glob = File.join(TMP, '*.log')
    end

    def test_initialize
      assert_equal [], Dir.glob(@glob)

      # create a new appender
      ap = Logging.appenders.rolling_file(NAME, :filename => @fn)
      assert_equal @fn, ap.filename
      assert File.exist?(@fn)
      assert_equal 0, File.size(@fn)

      ap << "Just a line of text\n"   # 20 bytes
      ap.flush
      assert_equal 20, File.size(@fn)
      cleanup

      # make sure we append to the current file (not truncate)
      ap = Logging.appenders.rolling_file(NAME, :filename => @fn)
      assert_equal @fn, ap.filename
      assert_equal [@fn], Dir.glob(@glob)
      assert_equal 20, File.size(@fn)

      ap << "Just another line of text\n"   # 26 bytes
      ap.flush
      assert_equal 46, File.size(@fn)
      cleanup

      # setting the truncate option to true should roll the current log file
      # and create a new one
      ap = Logging.appenders.rolling_file(NAME, :filename => @fn, :truncate => true)

      log1 = sprintf(@fn_fmt, 1)
      assert_equal [log1, @fn], Dir.glob(@glob).sort
      assert_equal 0, File.size(@fn)
      assert_equal 46, File.size(log1)

      ap << "Some more text in the new file\n"   # 31 bytes
      ap.flush
      assert_equal 31, File.size(@fn)
      cleanup
    end

    def test_keep
      assert_equal [], Dir.glob(@glob)

      (1..12).each do |cnt|
        name = sprintf(@fn_fmt, cnt)
        File.open(name,'w') {|fd| fd.write 'X'*cnt}
      end
      FileUtils.touch(@fn)

      # keep only five files
      ap = Logging.appenders.rolling_file(NAME, :filename => @fn, :keep => 5)

      # we still have 13 files because we did not truncate the log file,
      # and hence, we did not roll all the log files
      assert_equal 13, Dir.glob(@glob).length

      # force the appender to roll the files
      ap.send :copy_truncate
      ap.instance_variable_get(:@roller).roll_files
      assert_equal 6, Dir.glob(@glob).length

      (1..5).each do |cnt|
        name = sprintf(@fn_fmt, cnt)
        assert_equal cnt-1, File.size(name)
      end
      cleanup
    end

    def test_age
      d_glob = File.join(TMP, 'test.*.log')
      dt_glob = File.join(TMP, 'test.*-*.log')
      age_fn = @fn + '.age'

      assert_equal [], Dir.glob(@glob)

      assert_raise(ArgumentError) do
        Logging.appenders.rolling_file(NAME, :filename => @fn, :age => 'bob')
      end

      ap = Logging.appenders.rolling_file(NAME, :filename => @fn, :age => 1)
      ap << "random message\n"
      assert_equal 1, Dir.glob(@glob).length

      now = ::File.mtime(age_fn)
      start = now - 42
      ::File.utime(start, start, age_fn)
      ap.instance_variable_set(:@age_fn_mtime, nil)
      ap << "another random message\n"
      assert_equal 1, Dir.glob(dt_glob).length

      Dir.glob(d_glob).each {|fn| ::File.delete fn}
      cleanup

      ap = Logging.appenders.rolling_file(NAME, :filename => @fn, 'age' => 'daily')
      ap << "random message\n"
      assert_equal 1, Dir.glob(@glob).length

      now = ::File.mtime(age_fn)
      start = now - 3600 * 24
      ::File.utime(start, start, age_fn)
      ap.instance_variable_set(:@age_fn_mtime, nil)

      sleep 0.250
      ap << "yet another random message\n"
      assert_equal 0, Dir.glob(dt_glob).length
      assert_equal 1, Dir.glob(d_glob).length

      Dir.glob(d_glob).each {|fn| ::File.delete fn}
      cleanup

      ap = Logging.appenders.rolling_file(NAME, :filename => @fn, :age => 'weekly')
      ap << "random message\n"
      assert_equal 1, Dir.glob(@glob).length

      start = now - 3600 * 24 * 7
      ::File.utime(start, start, age_fn)
      ap.instance_variable_set(:@age_fn_mtime, nil)

      sleep 0.250
      ap << "yet another random message\n"
      assert_equal 0, Dir.glob(dt_glob).length
      assert_equal 1, Dir.glob(d_glob).length

      Dir.glob(d_glob).each {|fn| ::File.delete fn}
      cleanup

      ap = Logging.appenders.rolling_file(NAME, :filename => @fn, :age => 'monthly')
      ap << "random message\n"
      assert_equal 1, Dir.glob(@glob).length

      start = now - 3600 * 24 * 31
      ::File.utime(start, start, age_fn)
      ap.instance_variable_set(:@age_fn_mtime, nil)

      sleep 0.250
      ap << "yet another random message\n"
      assert_equal 0, Dir.glob(dt_glob).length
      assert_equal 1, Dir.glob(d_glob).length
    end

    def test_size
      assert_equal [], Dir.glob(@glob)

      ap = Logging.appenders.rolling_file(NAME, :filename => @fn, :size => 100)

      ap << 'X' * 100; ap.flush
      assert_equal 1, Dir.glob(@glob).length
      assert_equal 100, File.size(@fn)

      # this character is appended to the log file (bringing its size to 101)
      # and THEN the file is rolled resulting in a new, empty log file
      ap << 'X'
      assert_equal 2, Dir.glob(@glob).length
      assert_equal 0, File.size(@fn)

      ap << 'X' * 100; ap.flush
      assert_equal 2, Dir.glob(@glob).length
      assert_equal 100, File.size(@fn)

      ap << 'X'
      assert_equal 3, Dir.glob(@glob).length
      assert_equal 0, File.size(@fn)

      cleanup
    end

    def test_file_removed
      assert_equal [], Dir.glob(@glob)

      ap = Logging.appenders.rolling_file(NAME, :filename => @fn, :size => 100)

      ap << 'X' * 100; ap.flush
      assert_equal 1, Dir.glob(@glob).length
      assert_equal 100, File.size(@fn)
    end

    private
    def cleanup
      unless Logging.appenders[NAME].nil?
        Logging.appenders[NAME].close false
        Logging.appenders[NAME] = nil
      end
    end

  end  # class TestRollingFile
end  # module TestAppenders
end  # module TestLogging

# EOF

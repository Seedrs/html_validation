module PageValidations
  # Namespace planned for future additional validations


  class HTMLValidation

    @@default_tidy_flags = ['-quiet', '-indent']

    # The data_folder is where we store our output. options[:tidyopts], which defaults to "-qi"
    # can be used to override the command line options to html tidy.  On *nix, man tidy to see
    # what else you might use for this string instead of "-qi", however "-qi" is probably what
    # you want 95% of the time.

    # You may also pass :ignore_proprietary => true as an option to suppress messages like:
    #  line 1 column 176 - Warning: <textarea> proprietary attribute "wrap"
    #  line 1 column 176 - Warning: <textarea> proprietary attribute "spellcheck"

    # It may be useful to pass a subfolder in your project as the data_folder, so your
    # HTML Validation status and validation results are stored along with your source.

    # :folder_for_data: Storage folder path to save, and look for, result files.
    # :options: hash passed directly to HTMLValidationResult
    def initialize(folder_for_data = nil,  tidy_flags = [], options={})
      self.data_folder  = folder_for_data || default_result_file_path
      @tidy_flags       = tidy_flags
      @options          = options
    end


    # Default command line flags to pass when tidy is executed.
    # all tidy flags flags as an array of strings like ['--show-warnings false']
    # Note: Pass the entire string for each setting, NOT a name value pair
    # settings are available from:  tidy -h
    def self.default_tidy_flags
      @@default_tidy_flags
    end

    def self.default_tidy_flags=(val)
      @@default_tidy_flags = val
    end

    # Shortcut to enable/disable whether warnings are checked in Tidy.
    # Note that changing this setting (or any flag) can change how
    # the result files are seen in terms of their acceptance.
    # Meaning, if you have previously accepted a page with warnings either
    # on or off, you will probably need to re-run the 'validation review' command
    # following your first run with the new setting.
    def self.show_warnings=(val)
      if val
        @@default_tidy_flags.delete('--show-warnings false') # remove the flag (rely on default: true)
      else
        (@@default_tidy_flags << '--show-warnings false').uniq!
      end
    end


    # For each stored exception, yield an HTMLValidationResult object to allow the user to
    # call .accept! on the exception if it is OK.
    def each_exception
      Dir.chdir(@data_folder)
      Dir.glob("*.exceptions.txt").each do |file|
        if File.open(File.join(@data_folder, file), 'r').read != ''
          yield HTMLValidationResult.load_from_files(file.gsub('.exceptions.txt',''))
        end
      end
    end

    # :html:      The html to validate
    # :resource:  Used to create a name for the result file, nothing more. Usually a URL.
    def validation(html, resource_name)
      resource_data_path = File.join(@data_folder, filenameize(resource_name))
      HTMLValidationResult.new(resource_name, html, resource_data_path,  @tidy_flags, @options)
    end

    def data_folder=(path)
      FileUtils.mkdir_p(path)
      @data_folder = path
    end

    def default_result_file_path
      posix      = RbConfig::CONFIG['host_os'] =~ /(darwin|linux)/
      rootpath   = Rails.root if defined?(Rails)
      rootpath ||= HTMLValidationMatcher.data_path if HTMLValidationMatcher.data_path
      rootpath ||= posix ? '/tmp/' : "c:\\tmp\\"
      File.join(rootpath, '.validation')
    end

    private

    # Takes a url or filepath qne trims and sanitizes it for use as a filename.
    def filenameize(path)
      path.gsub!(/www.|^(http:\/\/|\/|C:\\)/, '')
      path.gsub(/[^0-9A-Za-z.]/, '_')
    end

  end
end
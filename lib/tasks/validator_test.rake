namespace :validator do
  desc "Test ReadWriteValidator with a given path"
  task :test, [:path] => :environment do |_t, args|
    if args[:path].blank?
      puts "Usage: rake validator:test[/path/to/test]"
      puts "Example: rake validator:test[/tmp/mydir]"
      exit 1
    end

    path = args[:path]
    puts "=" * 80
    puts "ReadWriteValidator Diagnostic Report"
    puts "=" * 80
    puts "Testing path: #{path}"
    puts "-" * 80

    # Check if path exists
    if File.exist?(path)
      puts "✓ Path exists"
    else
      puts "✗ Path does not exist"
      puts "\nValidation would fail before ReadWriteValidator runs."
      exit 0
    end

    # Check if it's a directory
    if FileTest.directory?(path)
      puts "✓ Is a directory"
    else
      puts "✗ Not a directory (is a file or other type)"
      puts "  Error message: 'is not a directory'"
    end

    # Check readability
    if FileTest.readable?(path)
      puts "✓ Is readable"
    else
      puts "✗ Not readable"
      puts "  Error message: 'must be readable'"
    end

    # Check writability
    if FileTest.writable?(path)
      puts "✓ Is writable"
    else
      puts "✗ Not writable"
      puts "  Error message: 'must be writable'"
    end

    # Check subfolders
    if File.exist?(path) && FileTest.directory?(path)
      puts "-" * 80
      puts "Subfolder Analysis:"
      puts "-" * 80

      begin
        entries = Dir.entries(path) - [".", ".."]
        if entries.empty?
          puts "  (No subfolders or files found)"
        else
          puts "  Found #{entries.count} items:"

          non_readable = []
          non_writable = []

          entries.each do |entry|
            entry_path = File.join(path, entry)
            readable = FileTest.readable?(entry_path)
            writable = FileTest.writable?(entry_path)

            status = []
            status << "R" if readable
            status << "W" if writable
            status_str = status.join(",")

            type = if FileTest.directory?(entry_path)
              "[DIR]"
            elsif FileTest.file?(entry_path)
              "[FILE]"
            else
              "[OTHER]"
            end

            indicator = (readable && writable) ? "✓" : "✗"

            puts "    #{indicator} #{type} #{entry} (#{status_str})"

            non_readable << entry_path unless readable
            non_writable << entry_path unless writable
          end

          if non_readable.any?
            puts "\n  ✗ Non-readable items (#{non_readable.count}):"
            non_readable.each { |p| puts "      - #{p}" }
            puts "    Error message: 'includes non-readable subfolders'"
          end

          if non_writable.any?
            puts "\n  ✗ Non-writable items (#{non_writable.count}):"
            non_writable.each { |p| puts "      - #{p}" }
            puts "    Error message: 'includes non-writeable subfolders'"
          end

          if non_readable.empty? && non_writable.empty?
            puts "\n  ✓ All items are readable and writable"
          end
        end
      rescue => e
        puts "  ✗ Error reading directory: #{e.message}"
      end
    end

    # Test with actual Library model
    puts "-" * 80
    puts "Testing with Library Model:"
    puts "-" * 80

    begin
      # Create a test library instance (not saved)
      library = Library.new(
        name: "Test Library for Diagnostics",
        path: path,
        storage_service: "filesystem"
      )

      # Run validation
      is_valid = library.valid?

      if is_valid
        puts "✓ Library validation PASSED"
        puts "  The path would be accepted by the Library model"
      else
        puts "✗ Library validation FAILED"
        puts "  Errors:"
        library.errors.full_messages.each do |msg|
          puts "    - #{msg}"
        end
      end
    rescue => e
      puts "✗ Error during Library validation: #{e.message}"
      puts "  #{e.backtrace.first}"
    end

    puts "=" * 80
  end

  desc "Test ReadWriteValidator interactively"
  task interactive: :environment do
    puts "ReadWriteValidator Interactive Test Tool"
    puts "=" * 80
    puts "Enter paths to test (or 'quit' to exit)"
    puts

    loop do
      print "Path to test: "
      path = $stdin.gets&.chomp

      break if path.nil? || path.downcase == "quit" || path.downcase == "exit"

      next if path.empty?

      puts
      Rake::Task["validator:test"].reenable
      Rake::Task["validator:test"].invoke(path)
      puts
    end

    puts "Exiting interactive mode."
  end
end

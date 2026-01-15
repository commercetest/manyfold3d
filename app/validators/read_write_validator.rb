class ReadWriteValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?

    # Diagnostic logging
    Rails.logger.debug { "[ReadWriteValidator] Validating #{attribute}: #{value.inspect}" }

    unless FileTest.directory?(value)
      Rails.logger.debug { "[ReadWriteValidator] ✗ Not a directory: #{value}" }
      record.errors.add attribute, :not_a_directory
    else
      Rails.logger.debug { "[ReadWriteValidator] ✓ Is a directory" }
    end

    unless FileTest.readable?(value)
      Rails.logger.debug { "[ReadWriteValidator] ✗ Not readable: #{value}" }
      record.errors.add attribute, :non_readable
    else
      Rails.logger.debug { "[ReadWriteValidator] ✓ Is readable" }
    end

    unless FileTest.writable?(value)
      Rails.logger.debug { "[ReadWriteValidator] ✗ Not writable: #{value}" }
      record.errors.add attribute, :non_writable
    else
      Rails.logger.debug { "[ReadWriteValidator] ✓ Is writable" }
    end

    # Make sure subfolder permissions are OK as well
    if File.exist?(value) && record.errors.empty?
      Rails.logger.debug { "[ReadWriteValidator] Checking subfolders..." }
      subfolders = Dir.entries(value) - [".", ".."]
      Rails.logger.debug { "[ReadWriteValidator] Found #{subfolders.count} subfolders" }

      subfolders.each do |subfolder|
        path = File.join(value, subfolder)
        unless FileTest.readable?(path)
          Rails.logger.debug { "[ReadWriteValidator] ✗ Subfolder not readable: #{path}" }
          record.errors.add attribute, :non_readable_subfolder
        end
        unless FileTest.writable?(path)
          Rails.logger.debug { "[ReadWriteValidator] ✗ Subfolder not writable: #{path}" }
          record.errors.add attribute, :non_writable_subfolder
        end
      end

      if record.errors.empty?
        Rails.logger.debug { "[ReadWriteValidator] ✓ All subfolders are readable and writable" }
      end
    end
  end
end

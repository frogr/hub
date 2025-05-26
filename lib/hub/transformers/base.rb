module Hub
  module Transformers
    class Base
      attr_reader :config, :dry_run

      def initialize(config, dry_run: false)
        @config = config
        @dry_run = dry_run
      end

      def transform
        raise NotImplementedError, "Subclasses must implement the transform method"
      end

      protected

      def log(message)
        class_name = self.class.name&.split("::")&.last || "Base"
        puts "[#{class_name}] #{message}"
      end

      def write_file(path, content)
        if dry_run
          log "Would write to #{path}"
        else
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)
          log "Updated #{path}"
        end
      end

      def read_file(path)
        return "" unless File.exist?(path)
        File.read(path)
      end

      def find_files(pattern)
        Dir.glob(Rails.root.join(pattern))
      end

      def replace_in_file(path, replacements)
        return unless File.exist?(path)

        content = read_file(path)
        original_content = content.dup

        replacements.each do |old_value, new_value|
          content.gsub!(old_value, new_value)
        end

        if content != original_content
          write_file(path, content)
        end
      end

      def safe_class_name(name)
        # First split by non-alphanumeric, then capitalize each part
        name.split(/[^a-zA-Z0-9]+/).map(&:capitalize).join
      end

      def safe_module_name(name)
        safe_class_name(name)
      end

      def safe_constant_name(name)
        name.gsub(/[^a-zA-Z0-9]/, "_").upcase
      end

      def file_contains?(path, pattern)
        return false unless File.exist?(path)
        read_file(path).include?(pattern)
      end
    end
  end
end

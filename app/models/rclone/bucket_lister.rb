class Rclone::BucketLister
  attr_reader :provider

  def initialize(provider)
    @provider = provider
  end

  def list
    config_file = generate_temp_config
    output = execute_rclone(config_file)
    parse_bucket_list(output)
  ensure
    config_file&.close
    config_file&.unlink
  end

  private
    def generate_temp_config
      Tempfile.new([ "rclone", ".conf" ]).tap do |file|
        file.write(provider.rclone_config_section("remote"))
        file.flush
      end
    end

    def execute_rclone(config_file)
      command = [
        "rclone", "lsd", "remote:",
        "--config", config_file.path
      ]

      stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        raise Rclone::Error, "Failed to list buckets: #{stderr}"
      end

      stdout
    end

    def parse_bucket_list(output)
      output.lines.filter_map do |line|
        # rclone lsd output format: "          -1 2024-01-01 00:00:00        -1 bucket-name"
        parts = line.strip.split(/\s+/)
        parts.last if parts.length >= 5
      end.sort
    end
end

class Rclone::ConfigGenerator
  attr_reader :backup

  def initialize(backup)
    @backup = backup
  end

  def generate
    Tempfile.new([ "rclone", ".conf" ]).tap do |file|
      file.write(config_contents)
      file.flush
    end
  end

  private
    def config_contents
      source_provider = backup.source_storage.provider
      destination_provider = backup.destination_storage.provider

      source_config = source_provider.rclone_config_section("source")
      destination_config = destination_provider.rclone_config_section("destination")

      "#{source_config}\n#{destination_config}"
    end
end

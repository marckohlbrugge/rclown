module Provider::RcloneConfigurable
  extend ActiveSupport::Concern

  def rclone_config_section(name = "remote")
    case provider_type
    when "cloudflare_r2"
      cloudflare_r2_config(name)
    when "backblaze_b2"
      backblaze_b2_config(name)
    when "amazon_s3"
      amazon_s3_config(name)
    end
  end

  private
    def cloudflare_r2_config(name)
      <<~CONFIG
        [#{name}]
        type = s3
        provider = Cloudflare
        access_key_id = #{access_key_id}
        secret_access_key = #{secret_access_key}
        endpoint = #{endpoint}
        acl = private
      CONFIG
    end

    def backblaze_b2_config(name)
      config = <<~CONFIG
        [#{name}]
        type = b2
        account = #{access_key_id}
        key = #{secret_access_key}
      CONFIG
      config += "endpoint = #{endpoint}\n" if endpoint.present?
      config
    end

    def amazon_s3_config(name)
      config = <<~CONFIG
        [#{name}]
        type = s3
        provider = AWS
        access_key_id = #{access_key_id}
        secret_access_key = #{secret_access_key}
      CONFIG
      config += "region = #{region}\n" if region.present?
      config += "endpoint = #{endpoint}\n" if endpoint.present?
      config
    end
end

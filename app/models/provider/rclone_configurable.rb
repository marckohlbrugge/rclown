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
    when "s3_compatible"
      s3_compatible_config(name)
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

    # Generic S3 API (Linode, DigitalOcean Spaces, Wasabi, MinIO, Hetzner, ...).
    # "Other" turns off AWS-only behaviour like checksum trailers. Ceph-backed
    # providers (Linode among them) also reject requests whose signature covers
    # Accept-Encoding, so leave that header out of the signature.
    # See https://github.com/rclone/rclone/issues/8206
    def s3_compatible_config(name)
      config = <<~CONFIG
        [#{name}]
        type = s3
        provider = Other
        access_key_id = #{access_key_id}
        secret_access_key = #{secret_access_key}
        endpoint = #{endpoint}
        sign_accept_encoding = false
      CONFIG
      config += "region = #{region}\n" if region.present?
      config
    end
end

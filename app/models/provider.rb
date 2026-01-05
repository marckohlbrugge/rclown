class Provider < ApplicationRecord
  include RcloneConfigurable, BucketDiscoverable

  PROVIDER_TYPES = {
    cloudflare_r2: "Cloudflare R2",
    backblaze_b2: "Backblaze B2",
    amazon_s3: "Amazon S3"
  }.freeze

  enum :provider_type, {
    cloudflare_r2: "cloudflare_r2",
    backblaze_b2: "backblaze_b2",
    amazon_s3: "amazon_s3"
  }

  encrypts :access_key_id
  encrypts :secret_access_key

  has_many :storages, dependent: :destroy

  validates :name, presence: true
  validates :provider_type, presence: true
  validates :access_key_id, presence: true
  validates :secret_access_key, presence: true
  validates :endpoint, presence: true, if: :cloudflare_r2?

  def provider_type_name
    PROVIDER_TYPES[provider_type.to_sym]
  end
end

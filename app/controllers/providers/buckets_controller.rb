module Providers
  class BucketsController < ApplicationController
    include ProviderScoped

    def index
      @buckets = @provider.discover_buckets
      @error = nil
    rescue Rclone::Error => e
      @buckets = []
      @error = e.message
    end

    def create
      bucket_name = params[:bucket_name]

      if @provider.bucket_imported?(bucket_name)
        redirect_to @provider, alert: "Bucket already imported."
      else
        storage = @provider.import_bucket(bucket_name)
        redirect_to @provider, notice: "Bucket '#{bucket_name}' imported as storage."
      end
    end
  end
end

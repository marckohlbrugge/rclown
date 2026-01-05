module Providers
  class ConnectionTestsController < ApplicationController
    include ProviderScoped

    def create
      @provider.discover_buckets
      @success = true
      @message = "Connection successful"
    rescue Rclone::Error => e
      @success = false
      @message = e.message
    end
  end
end

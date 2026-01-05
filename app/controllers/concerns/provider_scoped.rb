module ProviderScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_provider
  end

  private
    def set_provider
      @provider = Provider.find(params[:provider_id])
    end
end

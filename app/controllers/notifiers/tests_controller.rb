module Notifiers
  class TestsController < ApplicationController
    before_action :set_notifier

    def create
      @notifier.test_delivery
      @success = true
      @message = "Test notification sent successfully"
    rescue => e
      @success = false
      @message = e.message
    end

    private

    def set_notifier
      @notifier = Notifier.find(params[:notifier_id])
    end
  end
end

class StorageChargeProcessingRecordsController < ApplicationController
  authorize_resource

  def ssl_required?
    true
  end
end
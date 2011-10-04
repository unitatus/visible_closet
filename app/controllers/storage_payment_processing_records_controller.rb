class StoragePaymentProcessingRecordsController < ApplicationController
  authorize_resource

  def ssl_required?
    true
  end
  
  def show
    @admin_page = :monthly_charges
    @record = StoragePaymentProcessingRecord.find(params[:id])
  end
  
  def index
    @admin_page = :monthly_charges
    @records = StoragePaymentProcessingRecord.all
  end
end
class StorageChargeProcessingRecordsController < ApplicationController
  authorize_resource

  def ssl_required?
    true
  end
  
  def show
    @admin_page = :monthly_charges
    @record = StorageChargeProcessingRecord.find(params[:id])
  end
  
  def destroy
    @record = StorageChargeProcessingRecord.find(params[:id])
    @record.destroy
    redirect_to "/storage_charge_processing_records"
  end
  
  def index
    @admin_page = :monthly_charges
    @records = StorageChargeProcessingRecord.all
  end
end
class ShipmentsController < ApplicationController
  authorize_resource
  
  def get_label
    shipment = Shipment.find(params[:id])

    send_data(shipment.shipment_label, :filename => shipment.shipment_label_file_name_short, :type => "application/pdf")
  end
end

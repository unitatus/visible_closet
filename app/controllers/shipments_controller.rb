class ShipmentsController < ApplicationController
  authorize_resource
  
  def get_label
    shipment = Shipment.find(params[:id])

    send_data(shipment.shipment_label, :filename => "shipment_#{shipment.id}_label.pdf", :type => "application/pdf")
  end
end

class RentalAgreementVersionsController < ApplicationController
  authorize_resource :class => false

  def ssl_required?
    true
  end
  
  # GET /rental_agreement_versions
  def index
    @admin_page = :legal
    @agreement_versions = RentalAgreementVersion.all
  end
  
  # GET /rental_agreement_versions/1
  def show
    @admin_page = :legal
    @agreement_version = RentalAgreementVersion.find(params[:id])
  end
  
  # GET /rental_agreement_versions/new
  def new
    @admin_page = :legal
    @agreement_version = RentalAgreementVersion.new
    @most_recent_agreement = RentalAgreementVersion.latest
  end
  
  # GET /rental_agreement_versions/1/edit
  def edit
    @admin_page = :legal
    @agreement_version = RentalAgreementVersion.find(params[:id])
  end
  
  # POST /rental_agreement_versions
  def create
    @admin_page = :legal
    @agreement_version = RentalAgreementVersion.new(params[:rental_agreement_version])

    if @agreement_version.save
      redirect_to(rental_agreement_versions_url)
    else
      render :action => "new"
    end
  end
  
  # PUT /rental_agreement_versions/1
  def update
    @admin_page = :legal
    @agreement_version = RentalAgreementVersion.find(params[:id])

    if @agreement_version.update_attributes(params[:rental_agreement_version])
      redirect_to(rental_agreement_versions_url)
    else
      render :action => "edit"
    end
  end
  
  def latest_agreement_ajax
    latest = RentalAgreementVersion.latest
    
    if latest
      send_data("<div class='fancybox-ma-content-holder'>" + latest.agreement_text + "</div>")
    else
      send_data("No agreement on file")
    end
  end
  
  def latest_agreement
    
  end
end

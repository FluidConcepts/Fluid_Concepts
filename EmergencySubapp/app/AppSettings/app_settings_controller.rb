require 'rho/rhocontroller'
require 'helpers/browser_helper'

class AppSettingsController < Rho::RhoController
  include BrowserHelper

  # GET /AppSettings
  def index
    @appsettingses = AppSettings.find(:all)
    render :back => '/app'
  end

  # GET /AppSettings/{1}
  def show
    @appsettings = AppSettings.find(@params['id'])
    if @appsettings
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /AppSettings/new
  def new
    @appsettings = AppSettings.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /AppSettings/{1}/edit
  def edit
    @appsettings = AppSettings.find(@params['id'])
    if @appsettings
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /AppSettings/create
  def create
    @appsettings = AppSettings.create(@params['appsettings'])
    redirect :action => :index
  end

  # POST /AppSettings/{1}/update
  def update
    @appsettings = AppSettings.find(@params['id'])
    @appsettings.update_attributes(@params['appsettings']) if @appsettings
    redirect :action => :index
  end

  # POST /AppSettings/{1}/delete
  def delete
    @appsettings = AppSettings.find(@params['id'])
    @appsettings.destroy if @appsettings
    redirect :action => :index  
  end
end

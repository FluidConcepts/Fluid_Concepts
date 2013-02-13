require 'rho/rhocontroller'
require 'helpers/browser_helper'

class AppSettingsController < Rho::RhoController
  include BrowserHelper

	# SET appSettings
	def setAppSettings
		#First Delete all previous settings objects
		Alert.show_status("Here","I got here","hide")
		AppSettings.delete_all()

		#Get the user's choices from the webpage...
		time_increment = @params['settings[time]']
		emergency_cb = @params['settings[EmergenciesCB]']
		weather_cb = @params['settings[WeatherCB]']
		news_cb = @params['settings[NewsCB]']
		notification_types = "";
		if emergency_cb
			notifcation_types += emergency_cb		
			notifcation_types += ","
		end
		if weather_cb		
			notifcation_types += weather_cb		
			notifcation_types += ","
		end
		if news_cb
			notifcation_types += news_cb		
		end
			

		#Then create a new AppSettings object with the user's choices
		@appsettings = AppSettings.create({"TimeIncrement" => time_increment, "NotificationTypes" => notification_types})
		ti = "Time Increment: " + AppSettings.find(:first).TimeIncrement
		nt = "Notification Types: " + AppSettings.find(:first).NotificationTypes
		text = ti + "/n" + nt
		Alert.show_status("Settings", "Time Increment: " + text, "hide")
	end	

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

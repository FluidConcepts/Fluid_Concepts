# Refactored 4/2/2013 Group
require 'rho/rhocontroller'
require 'helpers/browser_helper'

class AppSettingsController < Rho::RhoController
  include BrowserHelper

	# SET appSettings
	#@params TimeIncrement,EmergenciesCB, WeatherCB, NewsCB
	def setAppSettings
		#First Delete all previous settings objects
		AppSettings.delete_all()

		#Get the user's choices from the webpage...
		#Time Increment User's Selection
		time_increment = @params['TimeIncrement']
		#Emergency Alerts Checkbox
		emergency_cb = @params['EmergenciesCB']
		#Weather Alerts Checkbox
		weather_cb = @params['WeatherCB']
		#News Alerts Checkbox
		news_cb = @params['NewsCB']
		#Create variable to house Comma Seperated Values list
		notification_types = "";
		#If Emergency Checkbox was selected
		#Append to notification_types csv variable
		if emergency_cb
			notification_types += emergency_cb		
			notification_types += ","
		end
		#If Weather Checkbox was selected
		#Append to notification_types csv variable 
		if weather_cb		
			notification_types += weather_cb		
			notification_types += ","
		end
		#If News Checkbox was selected
		#Append to notification_types csv variable
		if news_cb
			notification_types += news_cb		
		end
			

		#Then create a new AppSettings object with the user's choices
		AppSettings.create({"TimeIncrement" => time_increment, "NotificationTypes" => notification_types})
		#Redirect to the index page of the AppSettings Controller
		redirect :action => :index
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

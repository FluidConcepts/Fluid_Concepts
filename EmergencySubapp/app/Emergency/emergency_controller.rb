require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'helpers/emergency_helper'
require 'rexml/document'
class EmergencyController < Rho::RhoController
  include BrowserHelper
  include REXML
  
  # Handle popup events.
  # ** This is currently broken. In the event user clicks  more info the color scheme 
  # ** and layout stop functioning correctly.
	def popup_handler
		title = @params['button_id']
		if title == "Dismiss"               
			Alert.hide_popup
		else
		end
		@emergency = Emergency.find(:first)
    if @emergency
      WebView.navigate(url_for( :action => :show, :id => @emergency[0].object))
    else
      WebView.navigate(url_for( :action => :index ))
    end 
	end		
	
	# Get rss feed and save to feed.xml in the app storage path
	def refresh_database
	  @emergencys = Emergency.find(:all)
	  if File.exists?(File.join(Rho::RhoApplication::get_base_app_path, "feed.xml"))
	    File.delete(File.join(Rho::RhoApplication::get_base_app_path, "feed.xml")) 
	    File.open(File.join(Rho::RhoApplication::get_base_app_path, "last.txt"), File::RDWR|File::CREAT){ |f|
	      f.flock(File::LOCK_EX)
	      f.write(@emergencys[0].date)
	      f.close}
	  end
    Rho::AsyncHttp.download_file(
      :url => "https://php.radford.edu/~softeng02/rss-sim/rss.php",
      :filename => File.join(Rho::RhoApplication::get_base_app_path, "feed.xml"),
      :headers => {},
      :callback => url_for(:action => :httpdownload_callback)
    )
	  sleep(2)
	  redirect :emergency_page
	end
	
	# Do this on download complete
	# Update the database
	def httpdownload_callback
    Emergency.delete_all()
    file = File.new(File.join(Rho::RhoApplication::get_base_app_path, "feed.xml"))
    doc = REXML::Document.new(file)
    firstLoop = true
    doc.elements.each("*/channel/item")do |elm|
      title = elm.elements["title"].text
      desc = elm.elements["description"].text
      date_time = elm.elements["pubDate"].text
      date_array = [date_time[0..16], date_time[16..date_time.length-6]]
      Emergency.create({ "title" => title, "description" => desc, "time" => date_array[1], "date" => date_array[0], "fullTime" => date_time})
    end
    file.close
	end
	
	# Find all emergencys
	def emergency_page
		@emergencys = Emergency.find(:all)
	end

  # GET /Emergency
  def index
    @emergencies = Emergency.find(:all)
    render :back => '/app'
  end

  # GET /Emergency/{1}
  def show
    @emergency = Emergency.find(@params['id'])
    if @emergency
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Emergency/new
  def new
    @emergency = Emergency.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Emergency/{1}/edit
  def edit
    @emergency = Emergency.find(@params['id'])
    if @emergency
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Emergency/create
  def create
    @emergency = Emergency.create(@params['emergency'])
    redirect :action => :index
  end

  # POST /Emergency/{1}/update
  def update
    @emergency = Emergency.find(@params['id'])
    @emergency.update_attributes(@params['emergency']) if @emergency
    redirect :action => :index
  end

  # POST /Emergency/{1}/delete
  def delete
    @emergency = Emergency.find(@params['id'])
    @emergency.destroy if @emergency
    redirect :action => :index  
  end
end
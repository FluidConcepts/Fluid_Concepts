require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'helpers/emergency_helper'
require 'rexml/document'
class EmergencyController < Rho::RhoController
  include BrowserHelper
  include REXML
  
  # Handle popup events
	def popup_handler
		title = @params['button_id']
		if title == "Dismiss"
			Alert.hide_popup
		else
		@emergency = Emergency.find(:all, :conditions =>{'title' => title})
      if @emergency.empty? == false
	  	WebView.navigate(url_for( :action => :show, :id => @emergency[0].object))
     else
      WebView.navigate(url_for( :action => :index ))
     end 
		end
	end		
	
	# Get rss feed and save to feed.xml in the app storage path
	def refresh_database
	  Emergency.delete_all()
	  @@rssfile = File.join(Rho::RhoApplication::get_base_app_path, "feed.xml")
    Rho::AsyncHttp.download_file(
      :url => "https://php.radford.edu/~softeng02/rss-sim/rss.php",
      :filename => @@rssfile,
      :headers => {},
      :callback => url_for(:action => :httpdownload_callback)
    )
	  sleep(2)
	  redirect :emergency_page
	end
	
	# Do this on download complete
	# Update the database
	def httpdownload_callback
    file = File.new(@@rssfile)
    doc = REXML::Document.new(file)
    doc.elements.each("*/channel/item")do |elm|
      title = elm.elements["title"].text
      desc = elm.elements["description"].text
      date_time = elm.elements["pubDate"].text
      date_array = [date_time[0..16], date_time[16..date_time.length-6]]
      Emergency.create({ "title" => title, "description" => desc, "time" => date_array[1], "date" => date_array[0]})
    end
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

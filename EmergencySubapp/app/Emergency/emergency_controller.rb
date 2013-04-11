require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'helpers/emergency_helper'
require 'rexml/document'
require 'time'
class EmergencyController < Rho::RhoController
  include BrowserHelper
  include REXML
  #####################################################
  # !!MAY NEED TO CONFIGURE :url AROUND LINE 48!!     #
  #####################################################
  # Handle popup events.
  # If more info is clicked navigate to the alerts info page
  # If dismiss is vlicked do nothing
	def popup_handler
		title = @params['button_id']
		if title == "Dismiss"               
			Alert.hide_popup
		else		
		  @emergency = Emergency.find(:first)
		  if @emergency
		    WebView.navigate(url_for( :action => :show, :id => @emergency.object))
		  else
		    WebView.navigate(url_for( :action => :index ))
		  end 
		end
	end	
	
	# Navigate to the myru portal
	def portal
	  WebView.navigate "http://myru.radford.edu/cp/home/displaylogin"
	end
	
	# Get rss feed and save to feed.xml in the app storage path
	def refresh_database
	  # Delete the stored data so new data is written correctly
	  @@feedPath = File.join(Rho::RhoApplication::get_base_app_path, "feed.xml")
	  @@shownPath = File.join(Rho::RhoApplication::get_base_app_path, "shown")
	  if File.exists?(@@feedPath)
	    File.delete(@@feedPath)
	  end
	  # Delete shown so the file isn't written incorrectly
	  if File.exists?(@@shownPath)
      File.delete(@@shownPath)
	  end
	  # Download the updated feed
    Rho::AsyncHttp.download_file(
      :url => "https://php.radford.edu/~softeng02/rss-sim/rss.php",
      :filename => @@feedPath,
      :headers => {},
      :callback => url_for(:action => :httpdownload_callback)
    )
	end
	
	# Do this on download complete
	# Update the database
	def httpdownload_callback
		# Delete all emergencies and refresh the database
    Emergency.delete_all()
    file = File.new(@@feedPath)
    doc = REXML::Document.new(file)
    firstLoop = true
    #Parse each item element in this XML document.
    doc.elements.each("*/channel/item")do |elm|
      title = elm.elements["title"].text
      desc = elm.elements["description"].text
      date_time = elm.elements["pubDate"].text
      date_array = [date_time[0..16], date_time[16..date_time.length-6]]
      category = elm.elements["category"].text
      # We want the "fulltime" element in our database to be a UNIX time-stamp because comparisons are easier.
      nixTimeStamp = Time.parse(date_time).to_i
      # Create this Emergency object in the database.
      Emergency.create({ "title" => title, "description" => desc, "time" => date_array[1], "date" => date_array[0], "fullTime" => nixTimeStamp, "category" => category})
      # This is a refresh call so the user will see the alert. Do not show a popup for any alert downloaded this
      # way.
      if firstLoop
        firstLoop = false
        File.open(@@shownPath, File::RDWR|File::CREAT){ |f|
          f.flock(File::LOCK_EX)
          f.write(nixTimeStamp)
          f.close}
      end
    end
    file.close
    WebView.navigate(url_for(:action => :emergency_page))
	end
	
	# Hide all alerts currently on the device
	def hide_all
	  emg = Emergency.find(:first)
	  if !emg.nil?
      File.open(File.join(Rho::RhoApplication::get_base_app_path, "hide"), 
        File::RDWR|File::CREAT){ |f|
          f.flock(File::LOCK_EX)
          f.write(emg.fullTime)      
          f.close
        }
     redirect :emergency_page
	  end
	end
	
	# Find all emergencys when the emergency page is loaded
	def emergency_page
		@emergencys = Emergency.find(:all)
	end

  # GET /Emergency
  # Default index
  def index
    @emergencies = Emergency.find(:all)
    render :back => '/app'
  end

  # GET /Emergency/{1}
  # Default show
  def show
    @emergency = Emergency.find(@params['id'])
    if @emergency
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Emergency/new
  # Default new
  def new
    @emergency = Emergency.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Emergency/{1}/edit
  # Default edit 
  def edit
    @emergency = Emergency.find(@params['id'])
    if @emergency
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Emergency/create
  # Default create
  def create
    @emergency = Emergency.create(@params['emergency'])
    redirect :action => :index
  end

  # POST /Emergency/{1}/update
  # Default update
  def update
    @emergency = Emergency.find(@params['id'])
    @emergency.update_attributes(@params['emergency']) if @emergency
    redirect :action => :index
  end

  # POST /Emergency/{1}/delete
  # Default delete
  def delete
    @emergency = Emergency.find(@params['id'])
    @emergency.destroy if @emergency
    redirect :action => :index  
  end
end

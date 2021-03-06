require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'rexml/document'
require 'time'
class HomeController < Rho::RhoController
  include BrowserHelper
  include REXML
  #####################################################
  # !!MAY NEED TO CONFIGURE :url AROUND LINE 35!!     #
  #####################################################
  # GET /Home
  def index
    @homes = Home.find(:all)
    render :back => '/app'
  end

  def checkNew
    # Open the file containing the information of the last update that was displayed and store 
    # it in value.
    @@shownPath = File.join(Rho::RhoApplication::get_base_app_path, "shown")
    @@feedPath = File.join(Rho::RhoApplication::get_base_app_path, "feed.xml")
    File.open(@@shownPath, 
      File::RDWR|File::CREAT){ |f|
        f.flock(File::LOCK_EX)
        @@value = f.read()
        f.close
    }  
    # Destroy feed.xml if it exists. We don't want our file to write improperly.
    if File.exists?(@@feedPath)
      File.delete(@@feedPath)
    end 
    # Download the new XML file representing the RSS feed. On download complete callback in 
    # emergency_controller will parse the XML and update the database.
    Rho::AsyncHttp.download_file(
      :url => "https://php.radford.edu/~softeng02/rss-sim/rss.php",
      :filename => @@feedPath,
      :headers => {},
      :callback => url_for(:action => :httpdownload_callback))
    Rho::Timer.start(4000, url_for(:action => :timer_callback), "test")
  end 
  
  # Do the download procedure for a non refresh call
  def httpdownload_callback
    Emergency.delete_all()
    file = File.new(@@feedPath)
    doc = REXML::Document.new(file)
    firstLoop = true
    #Parse each item element in this XML document.
    doc.elements.each("*/channel/item")do |elm|
      title = elm.elements["title"].text
      desc = elm.elements["description"].text
      date_time = elm.elements["pubDate"].text
      category = elm.elements["category"].text
      # We want the "fulltime" element in our database to be a UNIX time-stamp because comparisons are easier.
      alertTime = Time.parse(date_time)
      nixTimeStamp = alertTime.to_i
      date_array = "PlaceHolder", "PlaceHolder"
      # Convert the RSS pubDate to an easily readable format
      date_array[0] = alertTime.month.to_s + "/" + alertTime.day.to_s + "/" + alertTime.year.to_s
      if alertTime.hour > 12
        hours = alertTime.hour - 12
        pm = true
      else
        hours = alertTime.hour
        pm = false
      end
      date_array[1] = hours.to_s + ":" + alertTime.min.to_s
      if pm == true
        date_array[1] = date_array[1] + " PM"
      else
        date_array[1] = date_array[1] + " AM"
      end
      # Create this Emergency object in the database.
      Emergency.create({ "title" => title, "description" => desc, "time" => date_array[1], "date" => date_array[0], "fullTime" => nixTimeStamp, "category" => category})
    end
    file.close
  end
  
  # Start a new thread that will sleep for 5 seconds to allow parsing to complete and then 
  # check the database for to see if there is a new alert. 
  def timer_callback
    @@shownPath = File.join(Rho::RhoApplication::get_base_app_path, "shown")
    @emergency = Emergency.find(:first)        # Get the newly update database
    if(@emergency != nil)                      # Can't display pop-up with no alerts
      @filter = AppSettings.find(:first).NotificationTypes
      @filter = @filter.split(',')
      if(@emergency.fullTime > @@value && (@filter.include?(@emergency.category) || @emergency.category.eql?("3")))        # Only show pop-up if the newest hasn't been shown
        # Show the pop-up
        Alert.show_popup( {
          :message => @emergency.description, 
          :title => @emergency.title, 
          :icon => :info,
          :buttons => [{:id => @emergency.title, :title => 'More Info'},
          {:id => 'Dismiss', :title => 'Dismiss'}],
          :callback => url_for(:controller => :Emergency, :action => :popup_handler) } )
        # Delete the file first. 
        File.delete(@@shownPath)
        # Write the full date and time of the shown pop-up to the last.txt file. We use this above
        # to filter seen pop-ups.    
        File.open(@@shownPath, 
          File::RDWR|File::CREAT){ |f|
            f.flock(File::LOCK_EX)
            f.write(@emergency.fullTime)      
            f.close
        }
      end
    end        
    settings = AppSettings.find(:first)
    if(settings != "Never")
      settings = settings.TimeIncrement.to_i
      settings = settings * 60000
      Rho::Timer.start(settings, url_for(:action => :checkNew), "nothing")
    end
  end
  # GET /Home/{1}
  def show
    @home = Home.find(@params['id'])
    if @home
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Home/new
  def new
    @home = Home.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Home/{1}/edit
  def edit
    @home = Home.find(@params['id'])
    if @home
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Home/create
  def create
    @home = Home.create(@params['home'])
    redirect :action => :index
  end

  # POST /Home/{1}/update
  def update
    @home = Home.find(@params['id'])
    @home.update_attributes(@params['home']) if @home
    redirect :action => :index
  end

  # POST /Home/{1}/delete
  def delete
    @home = Home.find(@params['id'])
    @home.destroy if @home
    redirect :action => :index  
  end
end

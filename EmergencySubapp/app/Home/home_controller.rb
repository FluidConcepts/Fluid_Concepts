require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'rexml/document'
require 'time'
class HomeController < Rho::RhoController
  include BrowserHelper
  include REXML
  
  # GET /Home
  def index
    @homes = Home.find(:all)
    render :back => '/app'
  end

  def checkNew
    # Open the file containing the information of the last update that was displayed and store 
    # it in value.
    File.open(File.join(Rho::RhoApplication::get_base_app_path, "shown"), 
      File::RDWR|File::CREAT){ |f|
        f.flock(File::LOCK_EX)
        @@value = f.read()
        f.close
    }  
    # Destroy feed.xml if it exists. We don't want our file to write improperly.
    if File.exists?(File.join(Rho::RhoApplication::get_base_app_path, "feed.xml"))
      File.delete(File.join(Rho::RhoApplication::get_base_app_path, "feed.xml"))
    end 
    # Download the new XML file representing the RSS feed. On download complete callback in 
    # emergency_controller will parse the XML and update the database.
    Rho::AsyncHttp.download_file(
      :url => "https://php.radford.edu/~softeng02/rss-sim/rss.php",
      :filename => File.join(Rho::RhoApplication::get_base_app_path, "feed.xml"),
      :headers => {},
      :callback => url_for(:action => :httpdownload_callback))
    Rho::Timer.start(4000, url_for(:action => :timer_callback), "test")
  end 
  
  # Do the download procedure for a non refresh call
  def httpdownload_callback
    Emergency.delete_all()
    file = File.new(File.join(Rho::RhoApplication::get_base_app_path, "feed.xml"))
    doc = REXML::Document.new(file)
    firstLoop = true
    #Parse each item element in this XML document.
    doc.elements.each("*/channel/item")do |elm|
      title = elm.elements["title"].text
      desc = elm.elements["description"].text
      date_time = elm.elements["pubDate"].text
      category = elm.elements["category"].text
      date_array = [date_time[0..16], date_time[16..date_time.length-6]]
      # We want the "fulltime" element in our database to be a UNIX time-stamp because comparisons are easier.
      nixTimeStamp = Time.parse(date_time).to_i
      # Create this Emergency object in the database.
      Emergency.create({ "title" => title, "description" => desc, "time" => date_array[1], "date" => date_array[0], "fullTime" => nixTimeStamp, "category" => category})
    end
    file.close
  end
  
  # Start a new thread that will sleep for 5 seconds to allow parsing to complete and then 
  # check the database for to see if there is a new alert. 
  def timer_callback
    @emergency = Emergency.find(:first)        # Get the newly update database
    if(@emergency != nil)                      # Can't display pop-up with no alerts
      @filter = @AppSettings.find(:first).NotificationTypes
      @filter = @filter.split(',')
      if(@emergency.fullTime > @@value && @filter.include?(@emergency.category))        # Only show pop-up if the newest hasn't been shown
        # Show the pop-up
        Alert.show_popup( {
          :message => @emergency.description, 
          :title => @emergency.title, 
          :icon => :info,
          :buttons => [{:id => @emergency.title, :title => 'More Info'},
          {:id => 'Dismiss', :title => 'Dismiss'}],
          :callback => url_for(:controller => :Emergency, :action => :popup_handler) } )
        # Delete the file first. 
        File.delete(File.join(Rho::RhoApplication::get_base_app_path, "shown"))
        # Write the full date and time of the shown pop-up to the last.txt file. We use this above
        # to filter seen pop-ups.    
        File.open(File.join(Rho::RhoApplication::get_base_app_path, "shown"), 
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

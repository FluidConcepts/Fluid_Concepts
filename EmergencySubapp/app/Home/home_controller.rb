require 'rho/rhocontroller'
require 'helpers/browser_helper'

class HomeController < Rho::RhoController
  include BrowserHelper

  
  # GET /Home
  def index
    @homes = Home.find(:all)
    render :back => '/app'
  end

  def checkNew
    # Open the file containing the information of the last update that was displayed and store 
    # it in value.
    File.open(File.join(Rho::RhoApplication::get_base_app_path, "last.txt"), 
      File::RDWR|File::CREAT){ |f|
        f.flock(File::LOCK_EX)
        @@value = f.read()
        f.close
    }  
    # Destroy feed.xml if it exists. We dont want our file to write improperly.
    if File.exists?(File.join(Rho::RhoApplication::get_base_app_path, "feed.xml"))
      File.delete(File.join(Rho::RhoApplication::get_base_app_path, "feed.xml"))
    end 
    # Download the new XML file representing the rss feed. On download complete callback in 
    # emergency_controller will parse the XML and update the database.
    Rho::AsyncHttp.download_file(
      :url => "https://php.radford.edu/~softeng02/rss-sim/rss.php",
      :filename => File.join(Rho::RhoApplication::get_base_app_path, "feed.xml"),
      :headers => {},
      :callback => url_for(:controller => :Emergency, :action => :httpdownload_callback))
    Rho::Timer.start(4000, url_for(:action => :timer_callback), "test")
  end 
  
  # Start a new thread that will sleep for 5 seconds to allow parsing to complete and then 
  # check the database for to see if there is a new alert. 
  def timer_callback
    @emergency = Emergency.find(:first)        # Get the newly update database
    if(@emergency != nil)                      # Can't display popup with no alerts
      if(@emergency.fullTime > @@value)        # Only show popup if the newest hasn't been shown
        # Show the popup
        Alert.show_popup( {
          :message => @emergency.description, 
          :title => @emergency.title, 
          :icon => :info,
          :buttons => [{:id => @emergency.title, :title => 'More Info'},
          {:id => 'Dismiss', :title => 'Dismiss'}],
          :callback => url_for(:controller => :Emergency, :action => :popup_handler) } )
        # Write the full date and time of the shown popup to the last.txt file. We use this above
        # to filter seen popups.    
        File.open(File.join(Rho::RhoApplication::get_base_app_path, "last.txt"), 
          File::RDWR|File::CREAT){ |f|
            f.flock(File::LOCK_EX)
            f.write(@emergency.fullTime)      
            f.close
        }
        settings = AppSettings.find(:first).TimeIncrement
        tInc = settings * 1000
        Alert.show_popup "tInc"
        Rho::Timer.start(tInc, url_for(:action => :checkNew), "nothing")
      end
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

require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'helpers/emergency_helper'
require '/lib/open-uri'
require '/lib/rss'

class EmergencyController < Rho::RhoController
  include BrowserHelper
  
  # Handle popup events
	def popup_handler
		title = @params['button_id']
		if title == "Dismiss"
			Alert.hide_popup
		else
		@emergency = Emergency.find(:all, :conditions =>{'title' => title})
      if @emergency.empty? == false
	  	WebView.navigate(url_for :action => :show, :id => @emergency[0].object)
     else
      WebView.navigate(url_for :action => :index)
     end 
		end
	end		
	
	# Get rss feed (This is currently broken)
	def refresh_database
	  Emergency.delete_all()
    url = 'https://php.radford.edu/~softeng02/rss-sim/rss.php'
    open(url) do |rss|
      feed = RSS::Parser.parse(rss)
      feed.items.each do |item|
        puts "Item: #{item.title}"
      end
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

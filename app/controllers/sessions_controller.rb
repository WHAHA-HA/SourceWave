class SessionsController < ApplicationController
  before_filter :check_login, :only => [:new]
  
  def new
  end
  
  def create
    # user = User.using(:main_shard).find_by_email(params[:email])
    user = User.using(:main_shard).where("email ilike :q", q: "%#{params[:email]}%").first
    if user && user.authenticate(params[:password])
      cookies.permanent[:auth_token] = user.auth_token
      user.update(current_sign_in_ip: get_user_ip)
      # session[:user_id] = user.id
      

      redirect_to dashboard_path('reactivate' => eval(params['params'])['reactivate'].to_s), notice: "Logged In"

      
      
    else
      flash.now.alert = "Email or password is invalid"
      render 'new'
    end
  end
  
  def destroy
    # session[:user_id] = nil
    current_user.update(last_sign_in_ip: get_user_ip) unless current_user.nil?
    cookies.delete(:auth_token)
    
    redirect_to root_url
  end  
  
  private
  
  def check_login
    unless current_user.nil? 
      redirect_to dashboard_path
    end
  end  

def get_user_ip
  ipAddr = request.headers["x-forwarded-for"]
  if ipAddr
  else
    ipAddr = request.remote_ip
  end
  
    ipAddr
  end
end

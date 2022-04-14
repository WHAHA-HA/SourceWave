class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  protect_from_forgery with: :exception, except: [:cancel_webhook, :charge_failure_webhook]


  def copy_to_clipboard
    render :layout => false
    msg = Clipboard.copy(params['msg'])
  end

  def initialize_cart
    @cart = DomainsCart.build_from_hash session
  end

  def check_active_subscription
    btnText = "Reactivate Subscription"
    unless current_user.nil?
      if current_user.subscription.nil? || current_user.subscription.status != 'active' || current_user.subscription.failed_transaction?
        flash[:error] = raw('Your account is inactive due to failure to pay. Please activate your subscription by using the "' + get_button_text + '" button below!')
        redirect_to account_path
      end
    end
  end

  private

  def current_user
    # @current_user ||= User.find(session[:user_id]) if session[:user_id]    #
    # @current_user ||= User.using(:main_shard).find_by_auth_token!(cookies[:auth_token]) if cookies[:auth_token]

    @current_user ||= User.using(:main_shard).where("auth_token = ?", cookies[:auth_token]).first if cookies[:auth_token]
    rescue ActiveRecord::RecordNotFound
      cookies.delete(:auth_token)
      redirect_to root_path

  end
  helper_method :current_user

  def authorize
    redirect_to login_url, alert: "Not authorized" if current_user.nil?
  end

  def get_button_text
    if current_user.subscription.nil?
      btnText = "Subscribe"
    elsif !current_user.subscription.nil? && current_user.subscription.failed_transaction?
      btnText = "Update Subscription"
    end
  end

end

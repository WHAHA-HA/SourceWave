class NotifyMailer < ApplicationMailer
  default from: "notification@sourcerevive.net"
  
  def notify(crawl_id)
    @crawl = Crawl.find(crawl_id)
    @user = @crawl.user

    mail to: @user.email, subject: 'Notification Alert'
  end
end

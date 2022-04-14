class AnchorText

  def initialize(params={})
    @params = params
  end

  def get_from_majestic
    url = @params['url']
    res = Unirest.get "http://api.majestic.com/api/json?app_api_key=#{ENV['majestic_api_key']}&cmd=GetAnchorText&item=#{url}"
    hash = JSON.parse res.raw_body
    return hash['DataTables']["AnchorText"]["Data"].map{|d| [d['AnchorText'], d["TotalLinks"]]}
  end

  def get_back_links
    url = @params['url']
    res = Unirest.get "http://api.majestic.com/api/json?app_api_key=#{ENV['majestic_api_key']}&cmd=GetBackLinkData&item=#{url}&Count=10datasource=fresh&MaxSameSourceURLs=1"
    hash = JSON.parse res.raw_body
    return hash['DataTables']["BackLinks"]["Data"].map{|d| [d['SourceURL'], d["AnchorText"]]}
  end

end

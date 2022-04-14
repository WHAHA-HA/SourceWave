module SitesHelper
  def get_anchor_text(id, url)
    ad = AvailableDomain.using(:main_shard).where(crawl_id: id.to_i).first
    if !ad.nil?
      available_domain = ad
    else
      available_domain = AvailableDomain.using(:main_shard).create!(crawl_id: id.to_i, url: url)
    end
    available_domain
  end
end

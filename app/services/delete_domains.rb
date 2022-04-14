class DeleteDomains
  attr_accessor :domain_cache
  attr_reader :page_infos, :user

  def initialize(params, user)
    @page_infos = params[:page_infos]
    @user = user
    @domain_cache = Rails.cache.read(["user/#{user.id}/available_domains"])
  end

  def go
    page_infos.each do |page_info|
      page_info_obj = PageInfo.new(page_info)
      page = Page.using(page_info_obj.processor).find_by id: page_info_obj.id
      if page
        crawl = page.crawl
        if crawl.user_id == user.id
          page.update_attribute :status_code, '204'
          crawl.available_sites.delete_if{|site_array| site_array[0] == page.id.to_s }
          crawl.save!
          delete_from_cache(page, crawl)
        end
      end
    end
    write_cache
  end

  def delete_from_cache(page, crawl)
    domain_cache.each do |crawl_hash|
      if crawl_hash['crawl_id'] == crawl.id
        crawl_hash['expired_domains'].delete_if{|site_array| site_array[0] == page.id.to_s }
      end
    end
  end

  def write_cache
    Rails.cache.write(["user/#{user.id}/available_domains"], domain_cache)
  end

  class PageInfo
    attr_reader :id, :processor

    def initialize(info)
      info_array = info.split(',')
      @id = info_array[0]
      @processor = info_array[1]
    end
  end
end
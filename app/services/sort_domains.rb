 class SortDomains
  attr_accessor :domains
  attr_reader :sort_key, :da_range, :tf_range, :da_range_str, :tf_range_str

  def initialize(user_id, params)
    @domains = Crawl.get_available_domains('user_id' => user_id)
    @sort_key = params[:sort].nil? ? 2 : params[:sort].to_i
    create_date_objects if sort_key == 8
    @da_range_str = params[:da_range]
    @tf_range_str = params[:tf_range]
    @da_range = Range.new(da_range_str)
    @tf_range = Range.new(tf_range_str)
  end

  def go
    filter_by_da_range
    filter_by_tf_range
    sort
    [domains, da_range_str, tf_range_str, da_range, tf_range]
  end

  def sort
    self.domains = domains.sort_by{|domain_array|
      sort_key == 8 ? domain_array[sort_key] : domain_array[sort_key].to_i
    }.reverse
  end

  def filter_by_da_range
    self.domains = domains.select{|domain_array| domain_array[2].to_i >= da_range.min } unless da_range.min == 0
    self.domains = domains.select{|domain_array| domain_array[2].to_i <= da_range.max } unless da_range.max == 100
  end

  def filter_by_tf_range
    self.domains = domains.select{|domain_array| domain_array[2].to_i >= tf_range.min } unless tf_range.min == 0
    self.domains = domains.select{|domain_array| domain_array[2].to_i <= tf_range.max } unless tf_range.max == 100
  end

  def create_date_objects
    self.domains = domains.map{|domain| domain[8] = DateTime.parse(domain[8]); domain }
  end

  class Range
    attr_reader :min, :max
    def initialize(range_str)
      if range_str.blank?
        @min = 0
        @max = 100
      else
        range_array = range_str.split(';')
        @min = range_array[0].to_i
        @max = range_array[1].to_i
      end
    end
  end

end
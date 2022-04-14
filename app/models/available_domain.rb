class AvailableDomain < ActiveRecord::Base

  before_save :set_anchor_texts

  def has_url?
    !url.to_s.empty?
  end

  def set_anchor_texts
    anchor_texts = AnchorText.new('url' => self.url).get_from_majestic
    puts "**************** anchor_texts: #{anchor_texts} **********************"
    self.anchor_texts = anchor_texts
  end

  def graph_anchor_texts
    self.anchor_texts.map{|a| [(a[0].include?(self.url) ? '(Website URL)' : a[0]), a[1]]}
  end
end

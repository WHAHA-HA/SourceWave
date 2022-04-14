class RenderStars
  
  include ActionView::Helpers
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  
  def initialize(rating, size=15)
    @rating = rating || 5
    @size = size
  end
  
  def render_stars
    content_tag(:div, star_images, :class => 'stars')
    # star_images
  end
  
  def star_images
    (0...5).map do |position|
      star_image(((@rating-position)*2).round)
    end.join.html_safe
  end
  
  def star_image(value)
    # image_tag("/#{star_type(value)}_star.png", :size => "#{@size}x#{@size}")
    ActionController::Base.helpers.image_tag("#{star_type(value)}_star.png", size: "#{@size}x#{@size}")
  end
  
  def star_type(value)
    if value <= 0
      'empty'
    elsif value == 1
      'half'
    else
      'full'
    end
  end

end
module ApplicationHelper

  # For Flash Messages
  def error_class_for(flash_type)
    case flash_type
      when 'success'
        'alert-success' # Green
      when 'error'
        'alert-danger' # Red
      when 'alert'
        'alert-danger' # Red
      when 'warn'
        'alert-warning' # Yellow
      when 'notice'
        'alert-info' # Blue
      else
        flash_type.to_s
    end
  end
  
  def modal(opts={}, header_text)
    defaults = {
      'class' => 'modal fade',
      'aria-hidden' => 'true',
      'aria-labelledby' => 'myModalLabel',
      'role' => 'dialog',
      'tabindex' => '-1'
    }
    options = defaults.merge opts.stringify_keys
    content_tag :div, options do
      content_tag :div, class: 'modal-dialog' do
        content_tag :div, class: 'modal-content' do
          output = content_tag :div, class: 'modal-header' do
            content = header_text.nil? ? '' : content_tag(:h3, header_text)
            content += image_tag 'close.png', :data => {dismiss: 'modal'}, :class => 'close'
            content
          end
          output += content_tag :div, class: 'modal-body' do
            yield if block_given?
          end
          output
        end
      end
    end
  end
  
  def render_stars(rating)
    RenderStars.new(rating).render
  end

end

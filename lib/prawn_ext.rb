module PrawnExt

  def fill_cell(content, f)
    bounding_box([f['x'],f['y']], :width => f['width'], :height => f['height']) do
      #stroke_bounds
      case f['type']
      when "image"
        image File.join($app_root, content),
        :position => :center,
        :vposition => :center,
        :fit => [f['width'], f['height']]
      else
        text_box  content.to_s, 
        :align => :center,
        :valign => :center,
        :overflow => :shrink_to_fit
      end
    end
  end

end

Prawn::Document.extensions << PrawnExt

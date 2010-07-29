class Capybara::Driver::Envjs::Node

  def jquery_trigger(event)
    driver.evaluate_script(<<-END_JS)
      $('##{self['id']}').trigger('#{event}');
    END_JS
  end

  def set_with_events(value)
    case node.getAttribute("type")
    when "checkbox", "radio"
      set_radio(value)
    else
      set_text_input(value)
    end
  end
  alias_method_chain :set, :events

  def set_radio(value)
    set_without_events(value)
    jquery_trigger('change')
  end

  def set_text_input(value)
    jquery_trigger('focus')
    set_without_events(value)
    jquery_trigger('keydown')
    jquery_trigger('keyup')
    jquery_trigger('change')
    jquery_trigger('blur')
  end

  def select_with_events(options)
    select_without_events(options)
    jquery_trigger('change')
  end
  alias_method_chain :select, :events

  # This is overridden because the default implementation only supports nodes
  # hidden by setting the style attribute, which doesn't take into account the
  # computed style
  def visible?
    all_unfiltered("./ancestor-or-self::*").none? do |capybara_node|
      capybara_node.node.style['display'] == 'none'
    end
  end
end

class Capybara::Driver::Envjs
  def env
    env = {}
    begin
      @referrer = request.url if last_response.content_type.include?('text/html')
      env["HTTP_REFERER"] = @referrer
    rescue Rack::Test::Error
      # no request yet
    end
    env
  end
end

module CapybaraHelpers
  def node_from_nokogiri(nokogiri_node)
    page.driver.class.const_get('Node').new(page.driver, nokogiri_node)
  end
end

World(CapybaraHelpers)

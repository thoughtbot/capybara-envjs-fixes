module CucumberJavascript
  MOCK_FB = %{
    <script type="text/javascript">
      function FB_RequireFeatures() { }
    </script>
  }
  MOCK_DEBUG = %{
    <script type="text/javascript">
      console = {
        log: function (text) {
          Ruby.Rails.logger().debug('*** Javascript: ' + text + ' ***');
        }
      };
    </script>
  }

  MOCK_SET_TIMEOUT = %{
    <script type="text/javascript">
      setTimeout = function() {
        arguments[0].call();
      };
    </script>
  }

  MOCK_JQUERY_FADE = %{
    <script type="text/javascript">
      (function() {
        $.fn.fadeOut = function() {
          if($.isFunction(arguments[0])) {
            arguments[0].call();
          } else if($.isFunction(arguments[1])) {
            arguments[1].call();
          }
          return this;
        };
        $.fn.fadeIn = function() {
          if($.isFunction(arguments[0])) {
            arguments[0].call();
          } else if($.isFunction(arguments[1])) {
            arguments[1].call();
          }
          return this;
        };
      })();
    </script>
  }
  MOCK_ENVJS = %{
    <script type="text/javascript">
    /* fixes the .value property on textareas in env.js */
    var extension = { get value() { return this.innerText; } };
    var valueGetter = extension.__lookupGetter__('value');
    HTMLTextAreaElement.prototype.__defineGetter__('value', valueGetter);
    </script>
  }
  MOCK_JAVASCRIPT = (MOCK_FB + MOCK_SET_TIMEOUT + MOCK_DEBUG + MOCK_ENVJS).freeze
  MOCK_JQUERY = MOCK_JQUERY_FADE.freeze

  # MOCK_XHR = %{
  #   <script type="text/javascript">
  #     var originalXMLHttpRequest = new XMLHttpRequest();

  #     XMLHttpRequest = function() {
  #       this.xml = originalXMLHttpRequest;
  #       return this;
  #     };

  #     XMLHttpRequest.prototype.getResponseHeader = function(key) {
  #       if(key == "content-type") { return "text/html; charset=utf-8"; }
  #     };

  #     XMLHttpRequest.prototype.open = function(method, url, async, username, password) {
  #       this.info = { method: method, url: url };
  #     };
  #     XMLHttpRequest.prototype.send = function(data) {
  #       this.responseText = Ruby.HolyGrail.XhrProxy.request(this.info, data);
  #       this.status = 200;
  #       this.readyState = 4;
  #       this.onreadystatechange();
  #     }
  #   </script>
  # }

  # def custom_javascript
  #   @__custom_javascript.join("\n")
  # end

  # def cucumber_js(code)
  #   HolyGrail::XhrProxy.context = self
  #   unless @__page && @__last_parsed_page == current_url
  #     current_page_body = rewrite_script_paths(current_dom.to_html)
  #     current_page_body.sub!("<head>", "<head>\n#{MOCK_JAVASCRIPT}")
  #     current_page_body.sub!("</body>", "\n#{MOCK_JQUERY}\n#{custom_javascript}\n</body>")
  #     current_page_body.gsub!(%r{<script src="http://[^"]+" type="text/javascript"></script>}, '')
  #     anchor = URI.parse(root_url).merge(current_url).fragment
  #     current_page_body.gsub!("selected>", 'selected="selected">')
  #     @__page = Harmony::AnchoredPage.new(current_page_body, anchor)
  #     @__last_parsed_page = current_url
  #   end
  #   previous_url = @__page.execute_js("window.location.href")
  #   executed_result = @__page.execute_js(code)
  #   new_url = @__page.execute_js("window.location.href")
  #   if new_url == previous_url
  #     page_without_xhr_mock_script = @__page.to_html.sub(MOCK_JAVASCRIPT, '').sub(MOCK_JQUERY, '')
  #     @response.body = fix_script_entities(page_without_xhr_mock_script)
  #     class << @response
  #       attr_accessor :dom
  #     end
  #     @response.dom = Nokogiri::HTML.parse(@response.body)
  #     webrat_session.current_scope.instance_variable_set(:@dom, @response.dom)
  #     current_dom
  #     executed_result
  #   else
  #     visit new_url
  #   end
  # end
end

Before('@javascript') do
  Capybara.current_session.driver.rack_mock_session.after_request do
    new_body = Capybara.current_session.driver.response.body
    new_body.gsub!("<head>", "<head>\n#{CucumberJavascript::MOCK_JAVASCRIPT}\n")
    new_body.sub!("</body>", "\n#{CucumberJavascript::MOCK_JQUERY}\n</body>")
    new_body.gsub!(%r{<script src="http://[^"]+" type="text/javascript"></script>}, '')
    Capybara.current_session.driver.response.instance_variable_set('@body', new_body)
  end
end

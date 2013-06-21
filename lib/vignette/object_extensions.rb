module ObjectExtensions

  # Extensions to the Array object
  module ArrayExtensions

    def crc
      Zlib.crc32(self.join)
    end

    # Test will select a random object from the Array
    def vignette(name=nil)
      key = "vignette_#{name || crc.abs.to_s(16)}"
      test_name = nil

      if name.blank?
        if caller[0].include?('filter.rb')
          # E.g /Users/hayesgm/animals/shadow/app/views/landing/family.html.haml:11:in `_app_views_landing_family_html_haml__3008026497873467685_70232967999960'
          # -> app/views/landing/family.html.haml:313c7f3a472883ba
          filename = caller[1].split(':')[0].gsub(Rails.root.to_s+'/','') # Take the view name
          test_name = "#{filename}:#{crc.abs.to_s(16)}"
        else
          # E.g /Users/hayesgm/animals/shadow/app/controllers/home_controller.rb:27:in `home'
          # -> app/controllers/home_controller:home:313c7f3a472883ba
          line = caller[0].gsub(Rails.root.to_s+'/','') # Take everything but the Rails root portion
          
          m = /(?<filename>[\w.\/]+):(?<line>\d+):in `(?<function>\w+)'/.match(line)
          
          if m && !m[:filename].blank? && !m[:function].blank?
            test_name = "#{m[:filename]}:#{m[:function]}:#{crc.abs.to_s(16)}"
          else # Fallback
            test_name = key
          end
        end
      else
        name
      end

      store = case Vignette.store
        when :cookies
          raise VignetteError::ConfigError, "Missing cookies configuration in Vignette.  Must access Vignette in controller within around_filter." if Vignette.cookies.nil?
          Rails.logger.debug [ 'Vignette::vignette', 'Cookies Sampling', key, Vignette.cookies[key] ] if Vignette.logging
          Vignette.cookies
        when :session
          raise VignetteError::ConfigError, "Missing session configuration in Vignette.  Must access Vignette in controller within around_filter." if Vignette.session.nil?
          Rails.logger.debug [ 'Vignette::vignette', 'Session Sampling', key, Vignette.session[key] ] if Vignette.logging
          Vignette.session
        else
          Rails.logger.debug [ 'Vignette::vignette', 'Random Sampling' ] if Vignette.logging
          {} # This is an empty storage
        end
      
      choice = store[key] ||= rand(length) # Store key into storage if not available
      
      # We're going to track all tests in request
      Vignette.request[:vignette] ||= {}
      Vignette.request[:vignette][:tests] ||= {}
      Vignette.request[:vignette][:tests][test_name] = choice

      self[choice.to_i]
    end

  end

  module ActionControllerExtensions

    def self.included(controller)
      controller.around_filter(:init_vignette)
    end

    private

    def init_vignette
      Vignette.request_config(request, session, cookies)
      yield
    ensure
      Vignette.clear_request # Clear request
    end

  end

end
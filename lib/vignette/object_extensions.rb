module ObjectExtensions

  # Extensions to the Array object
  module ArrayExtensions

    # Test will select a random object from the Array
    def vignette(name=nil)
      key = "vignette_#{name || hash}"
      test_name = if name.blank?
        if caller[0].include?('filter.rb')
          caller[1].split(':in')[0].gsub(Rails.root.to_s,'') # Take the view name
        else
          caller[0].gsub(Rails.root.to_s,'') # Take everything but the Rails root portion
        end
      else
        name
      end

      store = case Vignette.store
        when :cookies
          raise VignetteError::ConfigError, "Missing cookies configuration in Vignette.  Must access Vignette in controller within around_filter." if Vignette.cookies.nil?
          Vignette.cookies
        when :session
          raise VignetteError::ConfigError, "Missing session configuration in Vignette.  Must access Vignette in controller within around_filter." if Vignette.session.nil?
          # Rails.logger.debug [ 'Vignette::vignette', 'Session Sampling', key, Vignette.session[key], Vignette.session ]
          Vignette.session
        else
          # Rails.logger.debug [ 'Vignette::vignette', 'Random Sampling' ]
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
      Vignette.request_config(request, cookies, session)
      yield
    ensure
      Vignette.clear_request # Clear request
    end

  end

end
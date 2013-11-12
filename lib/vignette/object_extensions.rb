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

      store = Vignette.get_store

      choice = store[key] ||= Kernel.rand(length) # Store key into storage if not available
      result = self[choice.to_i]
      
      # Let's store keys where they are
      store[:v] = ( store[:v].present? ? JSON(store[:v]) : {} ).merge(test_name => result).to_json
      
      return result
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
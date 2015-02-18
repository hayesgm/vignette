module ObjectExtensions

  # Extensions to the Array object
  module ArrayExtensions

    def crc
      Zlib.crc32(self.join)
    end

    # Test will select a random object from the Array
    def vignette(name=nil)
      vignette_crc = self.crc().abs.to_s(16)

      key = "vignette_#{vignette_crc}"
      test_name = nil

      test_name = if name.blank?
        loc = caller_locations(1,1).first
        "(#{Vignette::strip_path(loc.absolute_path)}:#{loc.lineno})"
      else
        name
      end

      store = Vignette.get_store

      choice = store[key] ||= Kernel.rand(length) # Store key into storage if not available
      result = self[choice.to_i]

      # Let's store keys where they are (note, this truncates any other tests with the same name)
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
require 'java'
java_import 'it.unife.spf.ImageDiff'

module SPF
  module Gateway
    module Diff

      #Calls java class for compute the difference between images
      def self.diff(new_data, old_data)
        old_data = "" if old_data.nil?
        return ImageDiff.calculateDiff(old_data.to_java_bytes, new_data.to_java_bytes, 8.to_java(:int))
      end

    end
  end
end
